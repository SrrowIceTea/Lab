"""
文档 RAG 服务：教师上传课程资料 → 切块 → 向量化 → 存 MySQL → 学生问答检索。

存储方案（无需向量数据库）：
- MySQL 8.0，向量以 JSON 数组存 document_chunk.embedding_json
- 检索时读取候选块，在 Python 应用层用 numpy 计算余弦相似度
- 课程规模（几十个文档、几千个块）下，毫秒级完成，无需 Milvus/Qdrant

支持文档：.txt / .md / .pdf / .docx（pdf 用 pypdf，docx 用 python-docx，缺失时降级为纯文本读取）
"""
import io
import json
import logging
import math
import re
import time
import uuid
from datetime import datetime
from typing import Any, Dict, List, Optional, Tuple

import httpx

import config
from database import get_connection

logger = logging.getLogger(__name__)

try:
    import numpy as np
    _HAS_NUMPY = True
except ImportError:  # 无 numpy 时用纯 Python 兜底
    _HAS_NUMPY = False


# ─────────────────────────────────────────
#  表结构
# ─────────────────────────────────────────
def ensure_document_rag_schema() -> None:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                CREATE TABLE IF NOT EXISTS document_source (
                    source_id VARCHAR(64) NOT NULL PRIMARY KEY,
                    course_id BIGINT NOT NULL,
                    file_name VARCHAR(255) NOT NULL,
                    file_type VARCHAR(32) NOT NULL DEFAULT '',
                    file_size INT NOT NULL DEFAULT 0,
                    chunk_count INT NOT NULL DEFAULT 0,
                    status VARCHAR(32) NOT NULL DEFAULT 'ready',
                    error_message TEXT NULL,
                    uploaded_by BIGINT NULL,
                    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                    KEY idx_doc_source_course (course_id),
                    KEY idx_doc_source_created (created_at)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            """)
            cur.execute("""
                CREATE TABLE IF NOT EXISTS document_chunk (
                    chunk_id VARCHAR(64) NOT NULL PRIMARY KEY,
                    source_id VARCHAR(64) NOT NULL,
                    course_id BIGINT NOT NULL,
                    chunk_index INT NOT NULL,
                    content TEXT NOT NULL,
                    embedding_json JSON NOT NULL,
                    char_count INT NOT NULL DEFAULT 0,
                    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                    KEY idx_doc_chunk_course (course_id),
                    KEY idx_doc_chunk_source (source_id),
                    CONSTRAINT fk_doc_chunk_source FOREIGN KEY (source_id)
                        REFERENCES document_source (source_id) ON DELETE CASCADE
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            """)
        conn.commit()


# ─────────────────────────────────────────
#  Embedding 调用
# ─────────────────────────────────────────
def is_embedding_configured() -> bool:
    key = (config.EMBEDDING_API_KEY or "").strip()
    if not key:
        return False
    # 过滤 .env.example 里的占位符，避免误判为已配置
    lowered = key.lower()
    return not (
        lowered.startswith("your_")
        or lowered in ("changeme", "sk-xxx", "none", "null")
    )


async def embed_texts(texts: List[str]) -> List[List[float]]:
    """调用 SiliconFlow / OpenAI 兼容的 /embeddings 接口。"""
    if not is_embedding_configured():
        raise RuntimeError("未配置 EMBEDDING_API_KEY，请在 .env 中填写硅基流动 API Key")

    base = config.EMBEDDING_API_BASE.rstrip("/")
    url = f"{base}/embeddings"
    payload: Dict[str, Any] = {
        "model": config.EMBEDDING_MODEL,
        "input": texts,
    }
    # dimensions 降维：Qwen3-Embedding-8B 默认 4096，降到 1024 大幅省存储、够用
    if config.EMBEDDING_DIMENSIONS > 0:
        payload["dimensions"] = config.EMBEDDING_DIMENSIONS

    async with httpx.AsyncClient(timeout=config.EMBEDDING_TIMEOUT) as client:
        resp = await client.post(
            url,
            headers={
                "Authorization": f"Bearer {config.EMBEDDING_API_KEY}",
                "Content-Type": "application/json",
            },
            json=payload,
        )
        if resp.status_code != 200:
            raise RuntimeError(f"Embedding API HTTP {resp.status_code}: {resp.text[:400]}")
        data = resp.json()

    items = data.get("data") or []
    if not items:
        raise RuntimeError("Embedding API 返回空 data")
    vectors = [item.get("embedding") for item in items]
    if any(v is None for v in vectors):
        raise RuntimeError("Embedding API 返回格式异常（缺少 embedding）")
    return vectors


async def probe_embedding() -> Dict[str, Any]:
    """自检：真实调用一次 embedding，确认 Key、网络、维度都正常。"""
    if not is_embedding_configured():
        raise RuntimeError("尚未配置 EMBEDDING_API_KEY，请先在 .env 中填写硅基流动 API Key")
    started = time.perf_counter()
    vectors = await embed_texts(["立心 LMS 向量化连接测试"])
    latency_ms = int((time.perf_counter() - started) * 1000)
    dim = len(vectors[0]) if vectors and vectors[0] else 0
    expected = config.EMBEDDING_DIMENSIONS
    if expected > 0 and dim != expected:
        raise RuntimeError(
            f"向量维度不一致：接口返回 {dim}，配置为 {expected}，请检查 EMBEDDING_DIMENSIONS"
        )
    return {
        "ok": True,
        "model": config.EMBEDDING_MODEL,
        "dimensions": dim,
        "latencyMs": latency_ms,
    }


# ─────────────────────────────────────────
#  文档解析与切块
# ─────────────────────────────────────────
def extract_text(filename: str, content: bytes) -> str:
    ext = filename.lower().rsplit(".", 1)[-1] if "." in filename else "txt"
    if ext in ("txt", "md", "markdown", "csv"):
        return content.decode("utf-8", errors="replace")
    if ext == "pdf":
        try:
            from pypdf import PdfReader
            reader = PdfReader(io.BytesIO(content))
            return "\n".join((page.extract_text() or "") for page in reader.pages)
        except ImportError:
            raise RuntimeError("解析 PDF 需要 pypdf，请 pip install pypdf；或另存为 .txt/.md 上传")
    if ext in ("docx", "doc"):
        try:
            from docx import Document
            doc = Document(io.BytesIO(content))
            return "\n".join(p.text for p in doc.paragraphs if p.text.strip())
        except ImportError:
            raise RuntimeError("解析 Word 需要 python-docx，请 pip install python-docx；或另存为 .txt/.md 上传")
    # 兜底按文本处理
    return content.decode("utf-8", errors="replace")


def split_chunks(text: str, size: Optional[int] = None, overlap: Optional[int] = None) -> List[str]:
    size = size or config.DOC_CHUNK_SIZE
    overlap = overlap if overlap is not None else config.DOC_CHUNK_OVERLAP
    # 归一化空白
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text).strip()
    if not text:
        return []

    chunks: List[str] = []
    start = 0
    step = max(1, size - overlap)
    while start < len(text):
        end = min(start + size, len(text))
        chunk = text[start:end].strip()
        if chunk:
            chunks.append(chunk)
        if end >= len(text):
            break
        start += step
    return chunks


# ─────────────────────────────────────────
#  入库 / 删除 / 列表
# ─────────────────────────────────────────
async def ingest_document(
    course_id: int,
    filename: str,
    content: bytes,
    uploaded_by: Optional[int] = None,
) -> Dict[str, Any]:
    ensure_document_rag_schema()
    source_id = f"doc-{uuid.uuid4().hex[:16]}"
    ext = filename.lower().rsplit(".", 1)[-1] if "." in filename else "txt"

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """INSERT INTO document_source
                   (source_id, course_id, file_name, file_type, file_size, status, uploaded_by)
                   VALUES (%s,%s,%s,%s,%s,'processing',%s)""",
                (source_id, course_id, filename[:255], ext[:32], len(content), uploaded_by),
            )
        conn.commit()

    try:
        text = extract_text(filename, content)
        chunks = split_chunks(text)
        if not chunks:
            raise RuntimeError("文档内容为空或无法提取文本")

        # 分批 embedding，避免单次请求过大
        vectors: List[List[float]] = []
        batch = 16
        for i in range(0, len(chunks), batch):
            vectors.extend(await embed_texts(chunks[i:i + batch]))

        with get_connection() as conn:
            with conn.cursor() as cur:
                for idx, (chunk_text, vec) in enumerate(zip(chunks, vectors)):
                    cur.execute(
                        """INSERT INTO document_chunk
                           (chunk_id, source_id, course_id, chunk_index, content, embedding_json, char_count)
                           VALUES (%s,%s,%s,%s,%s,%s,%s)""",
                        (
                            f"{source_id}-c{idx:04d}", source_id, course_id, idx,
                            chunk_text, json.dumps(vec, separators=(",", ":")), len(chunk_text),
                        ),
                    )
                cur.execute(
                    "UPDATE document_source SET chunk_count=%s, status='ready' WHERE source_id=%s",
                    (len(chunks), source_id),
                )
            conn.commit()

        logger.info("文档入库成功：%s，%d 块", filename, len(chunks))
        return {
            "success": True,
            "sourceId": source_id,
            "courseId": course_id,
            "fileName": filename,
            "chunkCount": len(chunks),
            "status": "ready",
        }
    except Exception as exc:  # noqa: BLE001
        logger.exception("文档入库失败：%s", filename)
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "UPDATE document_source SET status='failed', error_message=%s WHERE source_id=%s",
                    (str(exc)[:1000], source_id),
                )
            conn.commit()
        return {
            "success": False,
            "sourceId": source_id,
            "courseId": course_id,
            "fileName": filename,
            "status": "failed",
            "error": str(exc),
        }


def delete_source(source_id: str, course_id: Optional[int] = None) -> bool:
    ensure_document_rag_schema()
    with get_connection() as conn:
        with conn.cursor() as cur:
            if course_id is not None:
                cur.execute(
                    "DELETE FROM document_source WHERE source_id=%s AND course_id=%s",
                    (source_id, course_id),
                )
            else:
                cur.execute("DELETE FROM document_source WHERE source_id=%s", (source_id,))
        conn.commit()
        return cur.rowcount > 0


def list_sources(course_id: Optional[int] = None) -> List[Dict[str, Any]]:
    ensure_document_rag_schema()
    with get_connection() as conn:
        with conn.cursor() as cur:
            if course_id is not None:
                cur.execute(
                    """SELECT source_id, course_id, file_name, file_type, file_size,
                              chunk_count, status, error_message, created_at
                       FROM document_source WHERE course_id=%s ORDER BY created_at DESC""",
                    (course_id,),
                )
            else:
                cur.execute(
                    """SELECT source_id, course_id, file_name, file_type, file_size,
                              chunk_count, status, error_message, created_at
                       FROM document_source ORDER BY created_at DESC LIMIT 200"""
                )
            rows = cur.fetchall() or []
    return [
        {
            "sourceId": r["source_id"],
            "courseId": r["course_id"],
            "fileName": r["file_name"],
            "fileType": r["file_type"],
            "fileSize": r["file_size"],
            "chunkCount": r["chunk_count"],
            "status": r["status"],
            "errorMessage": r["error_message"],
            "createdAt": r["created_at"].isoformat() if r.get("created_at") else None,
        }
        for r in rows
    ]


# ─────────────────────────────────────────
#  检索
# ─────────────────────────────────────────
def _cosine(a: List[float], b: List[float]) -> float:
    if _HAS_NUMPY:
        va, vb = np.array(a, dtype=np.float32), np.array(b, dtype=np.float32)
        denom = float(np.linalg.norm(va) * np.linalg.norm(vb))
        return float(np.dot(va, vb) / denom) if denom else 0.0
    dot = sum(x * y for x, y in zip(a, b))
    na = math.sqrt(sum(x * x for x in a))
    nb = math.sqrt(sum(y * y for y in b))
    return dot / (na * nb) if na and nb else 0.0


async def search(
    course_id: int,
    query: str,
    top_k: Optional[int] = None,
    min_score: float = 0.35,
) -> List[Dict[str, Any]]:
    """在该课程的文档块中检索与问题最相关的片段。"""
    if not config.ENABLE_DOCUMENT_RAG or not is_embedding_configured():
        return []
    ensure_document_rag_schema()

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """SELECT dc.chunk_id, dc.source_id, dc.chunk_index, dc.content,
                          dc.embedding_json, ds.file_name
                   FROM document_chunk dc
                   JOIN document_source ds ON ds.source_id = dc.source_id
                   WHERE dc.course_id=%s AND ds.status='ready'""",
                (course_id,),
            )
            rows = cur.fetchall() or []
    if not rows:
        return []

    [query_vec] = await embed_texts([query])
    scored: List[Tuple[float, Dict[str, Any]]] = []
    for r in rows:
        try:
            vec = json.loads(r["embedding_json"])
            score = _cosine(query_vec, vec)
        except Exception:  # noqa: BLE001
            continue
        if score >= min_score:
            scored.append((score, r))

    scored.sort(key=lambda x: x[0], reverse=True)
    k = top_k or config.DOC_TOP_K
    return [
        {
            "score": round(score, 4),
            "content": r["content"],
            "fileName": r["file_name"],
            "sourceId": r["source_id"],
            "chunkIndex": r["chunk_index"],
        }
        for score, r in scored[:k]
    ]


def build_rag_context(course_id: int, query: str, hits: List[Dict[str, Any]]) -> str:
    """把检索结果拼成可注入 system prompt 的文本。"""
    if not hits:
        return ""
    lines = ["\n## 课程资料参考（教师上传的文档，来自 RAG 检索）"]
    for i, hit in enumerate(hits, 1):
        lines.append(f"[{i}] 来源：{hit['fileName']}（相关度 {hit['score']:.2f}）")
        lines.append(hit["content"][:1200])
        lines.append("")
    lines.append("请优先依据以上课程资料回答学生的问题；若资料中没有相关内容，再结合通识回答并说明。")
    return "\n".join(lines)

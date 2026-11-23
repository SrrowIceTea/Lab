"""
视频伴侣服务：基于十讲逐字稿切片，为课程视频页提供
  1. 章节索引（按时间分块，带标题）
  2. 讲中点「没懂」时，取播放时刻附近的转写上下文
  3. 每讲三分钟摘要（LLM 生成，进程内缓存）

数据来自 video_transcripts.json（由 work/transcripts/t01..t10.txt 切片生成），
不依赖 MySQL，不改动任何现有表。
"""
import json
import logging
import re
from pathlib import Path
from typing import Any, Dict, List, Optional

import config
import llm_client

logger = logging.getLogger(__name__)

_DATA_PATH = Path(__file__).with_name("video_transcripts.json")
_DATA: Dict[str, Any] = {}
_SUMMARY_CACHE: Dict[int, str] = {}

# 每讲的官方介绍（与前端课程目录一致），摘要生成失败时作为兜底
_FALLBACK_SUMMARY = {
    1: "从 ChatGPT 到自动驾驶梳理 AI 发展脉络，提出给机器立心、价值驱动，并用乌鸦与鹦鹉的比喻讲清通用智能的方向。",
    2: "解释计算机视觉为何难在看得懂而非拍得清，从人眼的脑补机制讲到卷积网络逐层提取特征。",
    3: "围绕分词歧义、词向量和言外之意，讲机器如何理解与生成人类语言。",
    4: "从感知到认知差在推理，用婴儿实验和物理属性判断说明常识推理为何是 AI 的短板。",
    5: "从赫布原则到统计、功能、价值三层学习，讲机器如何靠经验成长以及过拟合问题。",
    6: "把机器人拆成场景理解与任务执行两大能力，用真实案例说明原理简单、实现困难。",
    7: "从蜂群蚁群到博弈论与心智理论，说明人类智能的社会性与多智能体协作。",
    8: "介绍数字孪生与物理仿真，让机器在虚拟世界中高速试错再迁移回现实。",
    9: "以 AI 续写贝多芬第十交响曲开场，讲音乐生成的难点、技术链路与创作边界。",
    10: "从智能成为一级学科讲到北大的学科布局与培养体系，回答中学生为何要学 AI。",
}


def _load() -> None:
    global _DATA
    if _DATA:
        return
    if not _DATA_PATH.exists():
        logger.error("视频转写数据不存在：%s", _DATA_PATH)
        return
    try:
        _DATA = json.loads(_DATA_PATH.read_text(encoding="utf-8"))
        logger.info("视频转写数据已加载：%d 讲", len(_DATA))
    except Exception as exc:  # noqa: BLE001
        logger.exception("加载视频转写数据失败：%s", exc)


def get_lecture(lecture: int) -> Optional[Dict[str, Any]]:
    _load()
    return _DATA.get(str(lecture))


def list_chapters(lecture: int) -> List[Dict[str, Any]]:
    """把切片按固定时长聚合成章节，返回可点击跳转的时间点。"""
    lec = get_lecture(lecture)
    if not lec:
        return []
    chunks = lec.get("chunks", [])
    if not chunks:
        return []

    grouped: List[Dict[str, Any]] = []
    current: List[Dict[str, Any]] = []
    window = 300  # 每章约 5 分钟

    for chunk in chunks:
        if current and chunk["startSec"] - current[0]["startSec"] >= window:
            grouped.append(current)
            current = []
        current.append(chunk)
    if current:
        grouped.append(current)

    chapters = []
    for idx, group in enumerate(grouped, 1):
        # 取该章第一片的开头 18 字做标题，去掉常见开场噪声
        raw = group[0]["text"][:24]
        title = re.sub(r"[《》\s]", "", raw)[:18]
        chapters.append({
            "index": idx,
            "start": group[0]["start"],
            "startSec": group[0]["startSec"],
            "end": group[-1]["end"],
            "title": title or f"第 {idx} 段",
            "chunkCount": len(group),
        })
    return chapters


def context_at(lecture: int, seconds: int, before: int = 1, after: int = 1) -> Dict[str, Any]:
    """取播放时刻附近的转写上下文，供讲中答疑注入 prompt。"""
    lec = get_lecture(lecture)
    if not lec:
        return {"lecture": lecture, "seconds": seconds, "text": "", "start": "", "end": ""}
    chunks = lec.get("chunks", [])
    if not chunks:
        return {"lecture": lecture, "seconds": seconds, "text": "", "start": "", "end": ""}

    idx = 0
    for i, c in enumerate(chunks):
        if c["startSec"] <= seconds:
            idx = i
        else:
            break

    lo, hi = max(0, idx - before), min(len(chunks), idx + after + 1)
    picked = chunks[lo:hi]
    return {
        "lecture": lecture,
        "lectureTitle": lec.get("title", ""),
        "seconds": seconds,
        "start": picked[0]["start"],
        "end": picked[-1]["end"],
        "text": "\n".join(c["text"] for c in picked),
    }


async def get_summary(lecture: int) -> str:
    """生成（并缓存）每讲三分钟摘要。LLM 不可用时返回内置兜底文案。"""
    if lecture in _SUMMARY_CACHE:
        return _SUMMARY_CACHE[lecture]
    lec = get_lecture(lecture)
    if not lec:
        return _FALLBACK_SUMMARY.get(lecture, "暂无摘要。")

    chunks = lec.get("chunks", [])
    sampled = chunks[:: max(1, len(chunks) // 40)][:40]
    digest = "\n".join(c["text"][:200] for c in sampled)

    system = "你是高中人工智能课的助教。请用简洁中文概括课程内容，突出核心概念和具体例子。"
    user = (
        f"课程：第{lecture}讲 {lec.get('title','')}\n"
        f"以下是该讲课程录像的转写节选（自动转写可能有个别错字或乱码，请按上下文理解），"
        f"请写一段 250 字左右的导读摘要，"
        f"包含：这一讲要解决什么问题、关键概念、最值得记住的例子。\n\n{digest}"
    )
    try:
        summary = await llm_client.chat_text(
            llm_client.build_messages(system, user), max_tokens=600
        )
        if not summary or len(summary) < 40:
            raise ValueError("摘要过短")
    except Exception as exc:  # noqa: BLE001
        logger.warning("生成第%d讲摘要失败，用兜底文案：%s", lecture, exc)
        summary = _FALLBACK_SUMMARY.get(lecture, "暂无摘要。")
    _SUMMARY_CACHE[lecture] = summary
    return summary


def build_video_context(lecture: int, seconds: int) -> str:
    """给 /api/chat 用的视频上下文片段。"""
    ctx = context_at(lecture, seconds)
    if not ctx["text"]:
        return ""
    return (
        f"\n【学生当前正在观看第 {lecture} 讲视频，播放到 {ctx['start']}（约 {seconds} 秒）】\n"
        f"此时视频中正在讲的内容（来自课程录像转写）：\n{ctx['text'][:1600]}\n"
        f"（请优先结合这段内容解释学生没懂的地方，不要泛泛而谈。）"
    )

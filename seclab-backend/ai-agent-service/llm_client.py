"""
本地 Agent 的大模型调用层（OpenAI Chat Completions 兼容协议）

替代原 Dify 平台：
- 直接请求任意 OpenAI 兼容的 /chat/completions（DeepSeek、通义、OpenAI、本地 vLLM 等）
- 提供流式（SSE）与非流式两种调用，并统一输出前端既有事件契约
- 不依赖 openai SDK，只用 httpx（requirements.txt 已有）

对外主要函数：
    stream_chat(messages, ...) -> AsyncIterator[dict]   产出 {"event": "...", ...}
    chat_text(messages, ...)   -> str
    chat_json(messages, ...)   -> dict/list（从回答中提取 JSON）
"""
import json
import logging
import re
from typing import Any, AsyncIterator, Dict, List, Optional

import httpx

import config

logger = logging.getLogger(__name__)

# SSE 事件名（与前端 FloatingChat.vue / guidance / 教师端保持一致）
EVENT_MESSAGE = "message"
EVENT_MESSAGE_END = "message_end"
EVENT_ERROR = "error"

_FAKE_REPLY = (
    "【本地测试模式】已收到你的问题。当前未配置真实大模型，"
    "请设置 LLM_API_BASE / LLM_API_KEY / LLM_MODEL 后重试。"
)


def is_configured() -> bool:
    """是否配置了可用的大模型 API"""
    return bool(config.LLM_API_BASE and config.LLM_API_KEY and config.LLM_MODEL)


def _endpoint() -> str:
    base = (config.LLM_API_BASE or "").rstrip("/")
    if base.endswith("/chat/completions"):
        return base
    return f"{base}/chat/completions"


def _headers() -> Dict[str, str]:
    headers = {"Content-Type": "application/json"}
    if config.LLM_API_KEY:
        headers["Authorization"] = f"Bearer {config.LLM_API_KEY}"
    return headers


def _payload(messages: List[Dict[str, str]], stream: bool, **kwargs) -> Dict[str, Any]:
    return {
        "model": kwargs.pop("model", None) or config.LLM_MODEL,
        "messages": messages,
        "stream": stream,
        "temperature": kwargs.pop("temperature", None)
        if kwargs.get("temperature") is not None
        else config.LLM_TEMPERATURE,
        "max_tokens": kwargs.pop("max_tokens", None) or config.LLM_MAX_TOKENS,
        **kwargs,
    }


async def stream_chat(
    messages: List[Dict[str, str]],
    *,
    user: str = "student",
    conversation_id: str = "",
    model: Optional[str] = None,
    temperature: Optional[float] = None,
    max_tokens: Optional[int] = None,
    timeout: Optional[int] = None,
) -> AsyncIterator[Dict[str, Any]]:
    """
    流式对话。产出与前端契约兼容的事件字典：
      {"event": "message", "answer": "...", "conversation_id": "..."}
      {"event": "message_end", "conversation_id": "...", "message_id": "..."}
      {"event": "error", "message": "..."}
    """
    if config.ENABLE_FAKE_LLM_FOR_TEST and not is_configured():
        for ch in _FAKE_REPLY:
            yield {"event": EVENT_MESSAGE, "answer": ch, "conversation_id": conversation_id}
        yield {"event": EVENT_MESSAGE_END, "conversation_id": conversation_id, "message_id": "fake"}
        return

    if not is_configured():
        yield {
            "event": EVENT_ERROR,
            "message": "尚未配置大模型：请设置 LLM_API_BASE / LLM_API_KEY / LLM_MODEL（支持任意 OpenAI 兼容接口）。",
        }
        return

    payload = _payload(
        messages,
        True,
        model=model,
        temperature=temperature,
        max_tokens=max_tokens,
    )
    timeout_value = timeout or config.LLM_TIMEOUT

    try:
        async with httpx.AsyncClient(timeout=timeout_value) as client:
            async with client.stream(
                "POST", _endpoint(), headers=_headers(), json=payload
            ) as response:
                if response.status_code != 200:
                    body = await response.aread()
                    detail = body.decode("utf-8", errors="replace")
                    logger.error("LLM HTTP %s: %s", response.status_code, detail[:500])
                    yield {
                        "event": EVENT_ERROR,
                        "message": f"大模型接口返回 HTTP {response.status_code}：{detail[:500]}",
                    }
                    return

                message_id = ""
                async for line in response.aiter_lines():
                    if not line or not line.startswith("data:"):
                        continue
                    data = line[5:].strip()
                    if data in ("", "[DONE]"):
                        continue
                    try:
                        chunk = json.loads(data)
                    except json.JSONDecodeError:
                        continue

                    if "id" in chunk and not message_id:
                        message_id = str(chunk["id"])

                    choices = chunk.get("choices") or []
                    if not choices:
                        continue
                    delta = choices[0].get("delta") or {}
                    answer = delta.get("content") or ""
                    if answer:
                        yield {
                            "event": EVENT_MESSAGE,
                            "answer": answer,
                            "conversation_id": conversation_id,
                        }

                yield {
                    "event": EVENT_MESSAGE_END,
                    "conversation_id": conversation_id,
                    "message_id": message_id,
                }
    except httpx.ConnectError as exc:
        yield {
            "event": EVENT_ERROR,
            "message": f"无法连接大模型服务（{config.LLM_API_BASE}）：{exc}",
        }
    except httpx.TimeoutException as exc:
        yield {"event": EVENT_ERROR, "message": f"大模型服务响应超时：{exc}"}
    except httpx.HTTPError as exc:
        yield {"event": EVENT_ERROR, "message": f"大模型服务 HTTP 错误：{exc}"}
    except Exception as exc:  # noqa: BLE001 - 流中不能抛异常，否则前端收到不完整响应
        logger.exception("stream_chat unexpected error")
        yield {"event": EVENT_ERROR, "message": f"AI 助手响应异常：{exc}"}


async def chat_text(
    messages: List[Dict[str, str]],
    *,
    model: Optional[str] = None,
    temperature: Optional[float] = None,
    max_tokens: Optional[int] = None,
    timeout: Optional[int] = None,
) -> str:
    """非流式对话，返回纯文本。教师分析 / 主动提示 / 题目生成等复用。"""
    if not is_configured():
        if config.ENABLE_FAKE_LLM_FOR_TEST:
            return _FAKE_REPLY
        raise RuntimeError("尚未配置大模型 API（LLM_API_BASE / LLM_API_KEY / LLM_MODEL）")

    payload = _payload(
        messages,
        False,
        model=model,
        temperature=temperature,
        max_tokens=max_tokens,
    )
    async with httpx.AsyncClient(timeout=timeout or config.LLM_TIMEOUT) as client:
        response = await client.post(_endpoint(), headers=_headers(), json=payload)
        if response.status_code != 200:
            raise RuntimeError(f"LLM HTTP {response.status_code}: {response.text[:500]}")
        data = response.json()
        choices = data.get("choices") or []
        if not choices:
            raise RuntimeError("LLM 返回空 choices")
        content = choices[0].get("message", {}).get("content") or ""
        return str(content).strip()


def extract_json(text: str) -> Any:
    """从模型回答中提取 JSON（兼容 ```json 代码块与前后解释文字）"""
    if not text:
        raise ValueError("空回答")
    fenced = re.search(r"```(?:json)?\s*([\s\S]*?)```", text, re.IGNORECASE)
    if fenced:
        text = fenced.group(1).strip()
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass
    decoder = json.JSONDecoder()
    for match in re.finditer(r"[\[{]", text):
        try:
            obj, _ = decoder.raw_decode(text[match.start():])
            return obj
        except json.JSONDecodeError:
            continue
    raise ValueError("回答中未找到合法 JSON")


async def chat_json(messages: List[Dict[str, str]], **kwargs) -> Any:
    """非流式对话并返回解析后的 JSON。"""
    text = await chat_text(messages, **kwargs)
    return extract_json(text)


def build_messages(system_prompt: str, user_prompt: str) -> List[Dict[str, str]]:
    """构造 OpenAI messages 结构"""
    return [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_prompt},
    ]

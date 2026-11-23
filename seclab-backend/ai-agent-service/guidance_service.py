"""Proactive guidance 信号处理服务。

职责：
1. 接收 Kotlin docker-service 发来的 GuidanceSignal（``/api/guidance/signal`` 端点调用）。
2. 调 :func:`error_repository.classify_error_excerpt` 分类错误（若 error_slice 非空）。
3. 调 :func:`error_repository.save_error_event` 持久化错误事件（镜像 learning_event）。
4. 调 :func:`ai_repository.ensure_guidance_conversation` 查找/创建会话。
5. 异步调本地 agent（:mod:`llm_client`.stream_chat）流式接口，把 chunk 通过
   :func:`guidance_stream_registry.publish` 推送给前端 SSE。
6. 流式结束后调 :func:`ai_repository.save_ai_message` +
   :func:`ai_repository.update_conversation_after_stream` 持久化。
7. 落 ``guidance_proactive_notes`` 表（由 :func:`save_guidance_proactive_note` 直接 INSERT）。

注意：本服务**不阻塞** signal 端点，所有耗时操作在 ``asyncio.create_task`` 中进行。
"""
import asyncio
import json
import logging
from datetime import datetime
from typing import Any, Optional
from uuid import uuid4

import config
import llm_client

import ai_repository
import error_repository
import guidance_stream_registry
from database import get_connection

logger = logging.getLogger(__name__)


# guidance_proactive_notes 建表 SQL（与 shujuku/guidance_proactive_notes.sql 一致）
GUIDANCE_PROACTIVE_NOTES_TABLE_SQL = """
CREATE TABLE IF NOT EXISTS guidance_proactive_notes (
    note_id VARCHAR(64) NOT NULL,
    lab_session_id VARCHAR(64) NULL,
    user_id BIGINT NULL,
    signal_id VARCHAR(64) NOT NULL,
    conversation_id VARCHAR(64) NOT NULL,
    message_id VARCHAR(64) NOT NULL,
    trigger_reason VARCHAR(64) NULL,
    ai_message LONGTEXT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (note_id),
    KEY idx_guidance_note_session_time (lab_session_id, created_at),
    KEY idx_guidance_note_user_time (user_id, created_at),
    KEY idx_guidance_note_signal (signal_id),
    KEY idx_guidance_note_conversation (conversation_id),
    KEY idx_guidance_note_message (message_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
""".strip()

_schema_ready = False


def ensure_guidance_schema() -> None:
    """Create guidance_proactive_notes table once per process（与 error_repository.ensure_error_schema 同风格）。"""
    global _schema_ready
    if _schema_ready:
        return
    with get_connection() as conn:
        with conn.cursor() as cursor:
            cursor.execute(GUIDANCE_PROACTIVE_NOTES_TABLE_SQL)
        conn.commit()
    _schema_ready = True


def _to_int(value: Any) -> Optional[int]:
    """安全转 int；None/空字符串/非数字 → None。"""
    if value is None or value == "":
        return None
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def _build_context(signal: dict[str, Any]) -> dict[str, Any]:
    """从 GuidanceSignal 提取 ai_conversation 上下文字段。"""
    return {
        "user_id": _to_int(signal.get("user_id")),
        "class_id": _to_int(signal.get("class_id")),
        "course_id": _to_int(signal.get("course_id")),
        "module_id": _to_int(signal.get("module_id")),
        "task_id": _to_int(signal.get("task_id")),
        "question_id": None,
    }


def _build_dify_inputs(signal: dict[str, Any]) -> dict[str, Any]:
    """从 GuidanceSignal 构造提示词上下文（供 system / user prompt 与落库复用）。

    函数名保留以兼容既有调用方；语义已从"外部平台的变量注入"改为
    "本地 agent 的提示词上下文"。返回值仍由 trigger_reason / container /
    lab_key / error_slice / recent_commands / lab_task_summary /
    frustration_score / locale 组成，并作为 context_injection 的原始上下文落库。

    注意：``recent_commands`` 先取最后 5 条再序列化，避免大量命令导致 JSON
    被截断成非法 JSON（评审缺口：原实现直接 ``json.dumps(...)[:800]`` 会破坏 JSON）。
    """
    raw_commands = signal.get("recent_commands") or []
    if isinstance(raw_commands, list):
        # 仅保留最后 5 条，避免大量命令撑爆 800 字符上限
        commands_to_serialize = raw_commands[-5:]
    else:
        commands_to_serialize = raw_commands
    return {
        "trigger_reason": str(signal.get("trigger_reason") or ""),
        "container_name": str(signal.get("container_name") or ""),
        "lab_key": str(signal.get("lab_key") or ""),
        "error_slice": (signal.get("error_slice") or "")[:800],
        "recent_commands": json.dumps(
            commands_to_serialize, ensure_ascii=False
        )[:800],
        "lab_task_summary": (signal.get("lab_task_summary") or "")[:800],
        "frustration_score": signal.get("frustration_score", 0),
        "locale": str(signal.get("locale") or "zh-CN"),
    }


def _build_query(signal: dict[str, Any], error_classified: Optional[dict[str, str]]) -> str:
    """构造本地 agent 的 user prompt（中文，启发式诊断风格）。

    在原有字段基础上补充 frustration_score 与 locale，让模型据此调整语气与语言。
    """
    container = signal.get("container_name", "")
    lab_key = signal.get("lab_key", "")
    reason = signal.get("trigger_reason", "")
    error_slice = (signal.get("error_slice") or "")[:400]
    commands = signal.get("recent_commands") or []
    task = signal.get("lab_task_summary", "")
    frustration = signal.get("frustration_score", 0)
    locale = signal.get("locale") or "zh-CN"

    parts = [
        f"学生在靶机 {container}（{lab_key}）上陷入无效试错，触发原因：{reason}。",
    ]
    if task:
        parts.append(f"当前任务摘要：{task[:200]}。")
    if error_classified:
        parts.append(
            f"已识别错误类型：{error_classified['error_signature']}"
            f"（{error_classified['error_category']}，严重度 {error_classified['severity']}）。"
        )
    if error_slice:
        parts.append(f"最近报错片段：\n```\n{error_slice}\n```")
    if commands:
        cmd_str = " | ".join(str(c) for c in commands[-3:])
        parts.append(f"最近执行的命令：{cmd_str}")
    parts.append(f"学生挫败度评分：{frustration}（越高越沮丧，请保持耐心与鼓励）。")
    parts.append(f"请使用 {locale} 语言回答。")
    parts.append("请用启发式提问的方式（不要直接给答案），引导学生自己发现下一步该检查什么。控制在 3-5 句话。")
    return "\n".join(parts)


def _build_system_prompt() -> str:
    """构造 system prompt：定义主动提示助教的角色与边界。"""
    return (
        "你是网络安全靶场实验的助教。当学生陷入无效试错时，"
        "用启发式提问引导其自主排查，不直接给出答案，也不代为执行任何命令。"
        "回答简洁、聚焦下一步可检查的方向。"
    )


def _build_guidance_messages(
    signal: dict[str, Any], error_classified: Optional[dict[str, str]]
) -> list[dict[str, str]]:
    """把上下文与错误分类折叠为 llm_client.build_messages 所需的 messages。"""
    return llm_client.build_messages(
        _build_system_prompt(), _build_query(signal, error_classified)
    )


def save_guidance_proactive_note(
    *,
    lab_session_id: Optional[str],
    user_id: Optional[int],
    signal_id: str,
    conversation_id: str,
    message_id: str,
    trigger_reason: str,
    ai_message: str,
) -> None:
    """落 guidance_proactive_notes 表（独立表便于按 lab_session_id 查询历史主动提示）。"""
    ensure_guidance_schema()
    note_id = f"gnote-{uuid4()}"
    now = datetime.utcnow()
    with get_connection() as conn:
        with conn.cursor() as cursor:
            cursor.execute(
                """
                INSERT INTO guidance_proactive_notes (
                    note_id, lab_session_id, user_id, signal_id,
                    conversation_id, message_id, trigger_reason,
                    ai_message, created_at
                ) VALUES (
                    %(note_id)s, %(lab_session_id)s, %(user_id)s, %(signal_id)s,
                    %(conversation_id)s, %(message_id)s, %(trigger_reason)s,
                    %(ai_message)s, %(created_at)s
                )
                """,
                {
                    "note_id": note_id,
                    "lab_session_id": lab_session_id,
                    "user_id": user_id,
                    "signal_id": signal_id,
                    "conversation_id": conversation_id,
                    "message_id": message_id,
                    "trigger_reason": trigger_reason,
                    "ai_message": ai_message,
                    "created_at": now,
                },
            )
        conn.commit()


def handle_signal(signal: dict[str, Any]) -> dict[str, Any]:
    """
    同步预处理：分类错误 + 持久化错误事件 + 查找/创建会话。

    Returns: ``{"conversation_id": str, "dify_conversation_id": Optional[str], "query": str, "inputs": dict, "messages": list, "user_id": Optional[int]}``

    其中 ``dify_conversation_id`` 为兼容字段（保留 DB 列名），语义为本地会话 id 或空值。
    """
    lab_session_id = signal.get("lab_session_id") or ""
    error_slice = signal.get("error_slice") or ""
    exit_code = _to_int(signal.get("exit_code"))
    user_id = _to_int(signal.get("user_id"))

    # 1. 分类错误（若有 error_slice）
    error_classified = None
    if error_slice:
        error_classified = error_repository.classify_error_excerpt(
            error_slice, exit_code=exit_code
        )

    # 2. 持久化错误事件（镜像 learning_event）
    if error_classified and lab_session_id:
        try:
            error_repository.save_error_event(
                {
                    "lab_session_id": lab_session_id or None,
                    "user_id": signal.get("user_id"),
                    "class_id": signal.get("class_id"),
                    "course_id": signal.get("course_id"),
                    "module_id": signal.get("module_id"),
                    "task_id": signal.get("task_id"),
                    "container_name": signal.get("container_name"),
                    "raw_excerpt": error_slice[:1024],
                    "error_signature": error_classified["error_signature"],
                    "error_category": error_classified["error_category"],
                    "severity": error_classified["severity"],
                    "source": "guidance-proactive",
                    "request_id": signal.get("request_id") or signal.get("signal_id"),
                    "occurred_at": signal.get("triggered_at") or datetime.utcnow().isoformat(),
                }
            )
        except Exception as e:
            logger.warning(
                "save_error_event failed signal_id=%s: %s", signal.get("signal_id"), e
            )

    # 3. 查找/创建会话（用 lab_session_id 兜底，避免空值）
    context = _build_context(signal)
    safe_lab_session_id = lab_session_id or f"anon-{signal.get('signal_id', uuid4())}"
    conv = ai_repository.ensure_guidance_conversation(
        lab_session_id=safe_lab_session_id,
        context=context,
    )

    # 4. 构造本地 agent 的提示词上下文与 messages
    query = _build_query(signal, error_classified)
    inputs = _build_dify_inputs(signal)
    messages = _build_guidance_messages(signal, error_classified)

    return {
        "conversation_id": conv["conversation_id"],
        # 兼容字段：保留 DB 列名，写入本地会话 id 或空值（不再来自外部平台）
        "dify_conversation_id": conv["dify_conversation_id"],
        "query": query,
        "inputs": inputs,
        "messages": messages,
        "user_id": user_id,
        "lab_session_id": safe_lab_session_id,
        "error_classified": error_classified,
    }


async def stream_guidance_to_subscribers(
    *,
    lab_session_id: str,
    signal_id: str,
    trigger_reason: str,
    conversation_id: str,
    dify_conversation_id: Optional[str],
    query: str,
    inputs: dict[str, Any],
    messages: Optional[list[dict[str, str]]] = None,
    user_id: Optional[int] = None,
    error_classified: Optional[dict[str, str]] = None,
) -> None:
    """
    异步任务：调本地 agent（llm_client.stream_chat）流式，把 chunk 广播给 SSE 订阅者，结束后持久化。

    在 ``asyncio.create_task`` 中调用，不阻塞 signal 端点。
    无订阅者时跳过大模型调用（节省成本）。
    """
    if guidance_stream_registry.subscriber_count(lab_session_id) == 0:
        logger.info(
            "guidance signal skipped (no SSE subscriber) lab_session_id=%s signal_id=%s",
            lab_session_id,
            signal_id,
        )
        return

    await guidance_stream_registry.publish(
        lab_session_id,
        {
            "type": "guidance_start",
            "signal_id": signal_id,
            "trigger_reason": trigger_reason,
            "conversation_id": conversation_id,
            "error_context": error_classified,
            "ts": datetime.utcnow().isoformat(),
        },
    )

    # 模型与超时：优先使用 guidance 专用配置，缺失时回退到通用配置
    model = config.LLM_GUIDANCE_MODEL or config.LLM_MODEL
    timeout = getattr(config, "LLM_GUIDANCE_TIMEOUT", None) or config.LLM_TIMEOUT

    if not messages:
        # 兜底：调用方未传 messages（如测试/旧入口）时，按已有 query 重新构造
        messages = llm_client.build_messages(_build_system_prompt(), query or "")

    complete_response = ""
    # 兼容字段：上游会话 id，用于回填 DB 的 dify_conversation_id 列
    upstream_conversation_id: Optional[str] = dify_conversation_id
    upstream_message_id: Optional[str] = None
    message_id = f"msg-{uuid4()}"

    try:
        async for event in llm_client.stream_chat(
            messages,
            user=str(user_id) if user_id is not None else "guidance-proactive",
            conversation_id=conversation_id,
            model=model,
            timeout=timeout,
        ):
            event_type = event.get("event")

            if event_type == llm_client.EVENT_MESSAGE:
                # 只转发 message 事件的 answer 增量文本
                answer = event.get("answer") or ""
                if answer:
                    complete_response += answer
                    await guidance_stream_registry.publish(
                        lab_session_id,
                        {
                            "type": "chunk",
                            "signal_id": signal_id,
                            "content": answer,
                            "ts": datetime.utcnow().isoformat(),
                        },
                    )

            elif event_type == llm_client.EVENT_MESSAGE_END:
                # 捕获上游会话/消息 id（由 llm_client 透传或生成）
                if event.get("conversation_id"):
                    upstream_conversation_id = event["conversation_id"]
                if event.get("message_id"):
                    upstream_message_id = event["message_id"]

            elif event_type == llm_client.EVENT_ERROR:
                error_msg = event.get("message") or "本地大模型调用失败"
                logger.error(
                    "guidance LLM stream error signal_id=%s: %s", signal_id, error_msg
                )
                await guidance_stream_registry.publish(
                    lab_session_id,
                    {
                        "type": "error",
                        "signal_id": signal_id,
                        "message": error_msg,
                        "ts": datetime.utcnow().isoformat(),
                    },
                )
                return
    except Exception as e:
        logger.exception("guidance LLM stream failed signal_id=%s: %s", signal_id, e)
        await guidance_stream_registry.publish(
            lab_session_id,
            {
                "type": "error",
                "signal_id": signal_id,
                "message": f"内部错误：{e.__class__.__name__}",
                "ts": datetime.utcnow().isoformat(),
            },
        )
        return

    # 持久化完整消息
    try:
        saved = ai_repository.save_ai_message(
            conversation_id=conversation_id,
            role="assistant",
            content=complete_response,
            event_name="guidance_proactive",
            hint_level=None,
            contains_context=True,
            raw_payload={
                "signal_id": signal_id,
                "trigger_reason": trigger_reason,
                "inputs": inputs,
                "upstream_conversation_id": upstream_conversation_id,
                "upstream_message_id": upstream_message_id,
            },
            message_id=message_id,
        )
        ai_repository.save_context_injection(
            conversation_id=conversation_id,
            message_id=saved["message_id"],
            context_type="guidance_signal",
            raw_context=inputs,
        )
        # 回填会话 id（兼容字段 dify_conversation_id：此处写入本地会话 id）
        if upstream_conversation_id and upstream_conversation_id != dify_conversation_id:
            ai_repository.update_conversation_after_stream(
                conversation_id=conversation_id,
                dify_conversation_id=upstream_conversation_id,
                status="active",
            )
        # 落 guidance_proactive_notes 表
        save_guidance_proactive_note(
            lab_session_id=lab_session_id or None,
            user_id=user_id,
            signal_id=signal_id,
            conversation_id=conversation_id,
            message_id=message_id,
            trigger_reason=trigger_reason,
            ai_message=complete_response,
        )
    except Exception as e:
        logger.exception("guidance persistence failed signal_id=%s: %s", signal_id, e)

    await guidance_stream_registry.publish(
        lab_session_id,
        {
            "type": "guidance_end",
            "signal_id": signal_id,
            "message_id": message_id,
            "conversation_id": conversation_id,
            # 兼容字段：保留旧字段名，另给出语义更清晰的新字段
            "dify_conversation_id": upstream_conversation_id,
            "upstream_conversation_id": upstream_conversation_id,
            "ts": datetime.utcnow().isoformat(),
        },
    )


def dispatch_signal_task(signal: dict[str, Any]) -> dict[str, Any]:
    """
    同步入口（供 FastAPI 端点调用）：

    1. 调 :func:`handle_signal` 做预处理（分类错误、落 error_event、ensure 会话）。
    2. 启动异步后台任务 :func:`stream_guidance_to_subscribers`。

    Returns: 供端点立即响应 202 的摘要::

        {
            "signal_id": str,
            "conversation_id": str,
            "subscriber_count": int,
            "accepted": True,
        }
    """
    prepared = handle_signal(signal)
    lab_session_id = prepared["lab_session_id"]
    signal_id = signal.get("signal_id") or f"sig-{uuid4()}"
    trigger_reason = signal.get("trigger_reason", "")

    # 启动后台流式任务（不阻塞当前请求）
    asyncio.create_task(
        stream_guidance_to_subscribers(
            lab_session_id=lab_session_id,
            signal_id=signal_id,
            trigger_reason=trigger_reason,
            conversation_id=prepared["conversation_id"],
            dify_conversation_id=prepared["dify_conversation_id"],
            query=prepared["query"],
            inputs=prepared["inputs"],
            messages=prepared.get("messages"),
            user_id=prepared.get("user_id"),
            error_classified=prepared.get("error_classified"),
        )
    )

    return {
        "signal_id": signal_id,
        "conversation_id": prepared["conversation_id"],
        "subscriber_count": guidance_stream_registry.subscriber_count(lab_session_id),
        "accepted": True,
    }

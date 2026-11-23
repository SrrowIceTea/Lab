"""
AI 答题陪练：为课堂实践题提供
  1. grade  — 按参考答案要点评分，给出命中/遗漏要点与改进建议
  2. hint   — 分步提示，绝不直接给出答案
  3. variant— 生成同知识点的变式题，供再练一遍

复用 llm_client（OpenAI 兼容大模型），题目与答案由前端随请求传入，
不依赖数据库。
"""
import logging
from typing import Any, Dict, List, Optional

import llm_client

logger = logging.getLogger(__name__)

_GRADE_SYSTEM = """你是高中人工智能课程的助教，负责批改学生的简答题。
严格按以下规则：
1. 只依据"参考答案要点"评判，不引入外部标准。
2. 逐条判断学生回答是否命中每个要点（意思接近即可，不要求措辞一致）。
3. 给出 0-100 的分数：命中要点比例为主，表达清晰度为辅。
4. 语气鼓励，指出遗漏时给出具体方向，不要嘲讽。
5. 只输出 JSON，不要其他文字，格式：
{"score": 85, "hitPoints": ["命中的要点原文"], "missedPoints": ["未命中的要点原文"], "comment": "一句话点评", "suggestion": "具体改进建议"}"""

_HINT_SYSTEM = """你是高中人工智能课程的助教，用苏格拉底式方法给学生提示。
规则：
1. 绝不直接给出答案或把答案要点原样念出来。
2. 用一个引导性问题、一个类比，或提示思考方向。
3. 每次只给一步提示，简短（不超过 120 字）。
4. 语言贴合高中生，友好、有启发性。
5. 只输出纯文本提示，不要 JSON、不要标题。"""

_VARIANT_SYSTEM = """你是高中人工智能课程的出题老师。
请根据原题，出一道考查相同知识点但情境或问法不同的变式题。
规则：
1. 题型与原题一致（单选/多选/简答）。
2. 如果是选择题，给出 3-4 个选项并标明正确答案下标（从0开始）。
3. 如果是简答题，给出参考答案要点。
4. 难度与原题相当，适合高中生。
5. 只输出 JSON，格式：
{"id": 9001, "type": "single-choice", "content": "题目", "options": ["A...","B..."], "score": 10, "answer": [1], "reference": "简答题参考答案", "analysis": "简短解析", "variantOf": 原题ID}"""


async def grade_answer(
    question: str,
    student_answer: str,
    reference: str,
    analysis: str = "",
) -> Dict[str, Any]:
    """按要点评分，返回结构化反馈。失败时返回一个保守的兜底结果。"""
    user = (
        f"题目：{question}\n"
        f"参考答案要点：{reference}\n"
        f"解析（如有）：{analysis}\n"
        f"学生回答：{student_answer}\n\n"
        f"请按规则评分并输出 JSON。"
    )
    try:
        data = await llm_client.chat_json(
            llm_client.build_messages(_GRADE_SYSTEM, user), max_tokens=600
        )
        if not isinstance(data, dict):
            raise ValueError("评分结果不是对象")
        score = data.get("score", 0)
        try:
            score = max(0, min(100, int(score)))
        except (TypeError, ValueError):
            score = 0
        return {
            "score": score,
            "hitPoints": data.get("hitPoints") or [],
            "missedPoints": data.get("missedPoints") or [],
            "comment": str(data.get("comment") or ""),
            "suggestion": str(data.get("suggestion") or ""),
            "graded": True,
        }
    except Exception as exc:  # noqa: BLE001
        logger.warning("AI 评分失败，返回兜底：%s", exc)
        return {
            "score": 0,
            "hitPoints": [],
            "missedPoints": [],
            "comment": "AI 评分暂不可用，请对照参考答案自行检查。",
            "suggestion": str(exc),
            "graded": False,
        }


async def give_hint(
    question: str,
    student_answer: str = "",
    reference: str = "",
    step: int = 1,
) -> str:
    """给一步提示，不泄露答案。"""
    user = (
        f"题目：{question}\n"
        f"学生目前的回答：{student_answer or '（还没有作答）'}\n"
        f"这是第 {step} 次提示，请给出与之前不同的引导角度。\n"
        f"请输出一步提示。"
    )
    try:
        return await llm_client.chat_text(
            llm_client.build_messages(_HINT_SYSTEM, user), max_tokens=300
        )
    except Exception as exc:  # noqa: BLE001
        logger.warning("AI 提示失败：%s", exc)
        return "先回想这节课讲的核心概念，再想想它能怎么用到这道题上。"


async def generate_variant(question: Dict[str, Any], seed: int = 0) -> Dict[str, Any]:
    """生成同知识点变式题。"""
    qtype = question.get("type", "short-answer")
    user = (
        f"原题ID：{question.get('id', 0)}\n"
        f"题型：{qtype}\n"
        f"题干：{question.get('content', '')}\n"
        f"选项：{question.get('options') or []}\n"
        f"参考答案/解析：{question.get('reference') or question.get('analysis') or ''}\n"
        f"请按要求输出变式题 JSON。"
    )
    try:
        data = await llm_client.chat_json(
            llm_client.build_messages(_VARIANT_SYSTEM, user), max_tokens=700
        )
        if not isinstance(data, dict):
            raise ValueError("变式题不是对象")
        # 规范字段，保证前端可直接渲染
        data.setdefault("type", qtype)
        data.setdefault("score", question.get("score", 10))
        data["id"] = 90000 + seed + int(question.get("id", 0)) % 1000
        data["variantOf"] = question.get("id")
        data["generatedBy"] = "llm"
        if data.get("type") != "short-answer" and not data.get("options"):
            data["options"] = question.get("options") or []
        return data
    except Exception as exc:  # noqa: BLE001
        logger.warning("变式题生成失败：%s", exc)
        return {
            "id": 90000 + int(question.get("id", 0)) % 1000,
            "type": qtype,
            "content": "（AI 变式题生成失败，请稍后重试）",
            "score": question.get("score", 10),
            "variantOf": question.get("id"),
            "generatedBy": "fallback",
            "error": str(exc),
        }

"""
课程上下文注入：让 AI 在对话前就知道学生正在学哪一讲、当前任务是什么、有哪些题目。

数据来源（按优先级）：
1. 前端随 /api/chat 传来的 lab_context（来自 aiModules.ts，是课程实际使用的数据源）
2. 后端本地知识库 knowledge_repository / standard_question_repository（MySQL 可用时作为补充）

产出的 system prompt 会明确告诉模型：
- 当前课程名称、类别、讲次
- 当前任务点名称与要求
- 本节题目列表（题干、类型、选项、分值）
- 行为约束：结合题目引导、不直接报答案、基于终端日志给具体下一步
"""
from typing import Any, Dict, List, Optional

SYSTEM_BASE = """你是「立心之约 · 中学生人工智能微课十讲」的 AI 学习助手，面向高中生。
你的职责是结合学生当前正在学习的课程、任务、题目和实际操作日志，给出具体、可执行的引导，而不是泛泛而谈。

行为准则：
1. 用高中生能听懂的语言，多用生活中的例子，避免堆砌术语。
2. 学生提问时，优先联系当前课程的知识点和题目来回答。
3. 不要直接给出题目的标准答案；先给提示，引导他自己思考。学生明确要求解析时再给完整讲解。
4. 当提供了终端操作日志时，要针对日志里真实出现的操作、结果或报错给建议，不要说"请把结果发给我"。
5. 回答简洁，重点突出，必要时用编号分点。
"""

QUESTION_TYPE_LABELS = {
    "single-choice": "单选题",
    "multiple-choice": "多选题",
    "short-answer": "简答题",
}


def _fmt_questions(questions: Optional[List[Dict[str, Any]]]) -> str:
    if not questions:
        return "（前端未提供题目列表）"
    lines: List[str] = []
    for idx, q in enumerate(questions, 1):
        if not isinstance(q, dict):
            continue
        qtype = QUESTION_TYPE_LABELS.get(str(q.get("type", "")), q.get("type", "题目"))
        score = q.get("score", "")
        score_text = f"（{score} 分）" if score != "" else ""
        lines.append(f"{idx}. [{qtype}]{score_text} {q.get('content', '')}")
        options = q.get("options")
        if isinstance(options, list) and options:
            for opt in options:
                lines.append(f"    {opt}")
        analysis = q.get("analysis")
        if analysis:
            lines.append(f"    【解析要点】{analysis}")
        reference = q.get("reference")
        if reference:
            lines.append(f"    【参考答案要点】{reference}")
    return "\n".join(lines) if lines else "（无题目）"


def build_system_prompt(
    lab_context: Optional[Dict[str, Any]] = None,
    *,
    knowledge_units: Optional[List[Dict[str, Any]]] = None,
    standard_questions: Optional[List[Dict[str, Any]]] = None,
) -> str:
    """根据课程上下文构造 system prompt。lab_context 可为空，此时退化为通用助手。"""
    ctx = lab_context or {}
    parts = [SYSTEM_BASE]

    course_section: List[str] = ["\n## 当前学习情境"]
    module_name = ctx.get("moduleName") or ctx.get("experimentTitle")
    course_id = ctx.get("courseId")
    module_id = ctx.get("moduleId") or ctx.get("experimentId")
    current_task = ctx.get("currentTask")
    session_id = ctx.get("labSessionId")

    if module_name:
        course_section.append(f"- 当前课程/实践：{module_name}")
    if course_id is not None:
        course_section.append(f"- 讲次编号：第 {course_id} 讲")
    elif module_id is not None:
        course_section.append(f"- 模块编号：{module_id}")
    if current_task:
        course_section.append(f"- 当前任务点：{current_task}")
    if session_id:
        course_section.append(f"- 学习会话：{session_id}")

    if len(course_section) > 1:
        parts.append("\n".join(course_section))
        parts.append(
            "请始终记住学生正处于上述学习情境中，回答要贴合这门课的内容与进度。"
        )

    questions = ctx.get("questions")
    if questions:
        parts.append(
            "\n## 本节题目（学生正在练习）\n"
            + _fmt_questions(questions)
            + "\n\n这些是本节配套练习。回答相关问题时请引用题目编号；"
            "学生答错时给提示而非直接公布答案。"
        )

    objectives = ctx.get("objectives")
    if objectives:
        if isinstance(objectives, (list, tuple)):
            objectives = "、".join(str(o) for o in objectives)
        parts.append(f"\n## 本节学习目标\n{objectives}")

    if knowledge_units:
        lines = []
        for unit in knowledge_units[:8]:
            if isinstance(unit, dict):
                title = unit.get("title") or unit.get("name") or ""
                content = unit.get("content") or unit.get("summary") or ""
                if title or content:
                    lines.append(f"- {title}：{content}")
        if lines:
            parts.append("\n## 课程知识库参考（本地 RAG 检索）\n" + "\n".join(lines))

    if standard_questions:
        lines = []
        for q in standard_questions[:5]:
            if isinstance(q, dict):
                content = q.get("content") or q.get("questionText") or ""
                if content:
                    lines.append(f"- {content}")
        if lines:
            parts.append("\n## 相关标准题目样例（本地 RAG 检索）\n" + "\n".join(lines))

    return "\n".join(parts)


def build_user_prompt(query: str, terminal_log: Optional[str] = None, log_tail: int = 80) -> str:
    """把学生问题和终端日志拼成 user message（本地模型无需 base64 绕 WAF）。"""
    if not terminal_log:
        return query
    lines = [line for line in terminal_log.splitlines() if line.strip()][-log_tail:]
    if not lines:
        return query
    return (
        f"{query}\n\n"
        f"【系统附加：学生最近 {len(lines)} 行课堂模拟终端操作日志】\n"
        + "\n".join(lines)
        + "\n\n（以上为系统自动附加的真实操作记录。请据此判断学生的操作进展，"
        "直接给出下一步建议，不要反问学生「你观察到了什么」。）"
    )

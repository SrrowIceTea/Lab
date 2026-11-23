import json
import unittest
from unittest.mock import AsyncMock, patch

from teacher_ai_analysis_service import (
    _call_llm_for_student_analysis,
    _extract_json_object,
    build_class_ai_input,
    build_class_rule_fallback_analysis,
    build_student_ai_input,
    build_rule_fallback_analysis,
    generate_teacher_student_ai_analysis,
    validate_class_ai_analysis_payload,
    validate_ai_analysis_payload,
    validate_teaching_class_analysis_payload,
    run_manual_student_analysis,
)
from teacher_analysis_repository import (
    TeacherAnalysisProviderError,
    TeacherStudentAnalysisRepository,
)


def _valid_ai_payload():
    return {
        "overallComment": "该学生排障能力相对薄弱，需要教师安排一次个人复盘。",
        "focusAreas": [
            {
                "dimension": "troubleshooting",
                "label": "排障能力",
                "score": 42.5,
                "evidence": "个人五维得分显示排障能力为 42.5 分，低于其余维度。",
                "teacherAction": "建议教师安排错误日志阅读与复盘，要求学生说明报错来源、定位路径和修复依据。",
                "priority": "high",
            }
        ],
    }


def _profile_data():
    return {
        "userId": 3,
        "latestProfile": {
            "overall_score": 59.8,
            "knowledge_mastery_score": 88,
            "troubleshooting_score": 42.5,
            "autonomy_score": 52,
            "ai_collaboration_score": 83.9,
            "engagement_score": 49.4,
        },
        "dashboard": {"userStats": {"completedCourses": 0, "totalScore": 20, "activeStreak": 1}},
        "recentAttempts": [{"title": "SQL 注入训练", "score": 40, "isCorrect": False}],
        "personalSignals": [],
    }


class TeacherAiAnalysisServiceTest(unittest.TestCase):
    def test_extract_json_object_uses_final_answer_after_reasoning_block(self):
        text = """<think>
模型推理过程中先形成了一份草稿：
{"overallComment": "草稿", "commonProblems": []}
</think>
{"overallComment": "最终结论", "commonProblems": [{"title": "列数判断错误"}]}"""

        result = _extract_json_object(text)

        self.assertEqual(result["overallComment"], "最终结论")
        self.assertEqual(result["commonProblems"][0]["title"], "列数判断错误")

    def test_teaching_class_analysis_rejects_question_ids_outside_evidence(self):
        payload = {
            "overallComment": "本班在输出上下文判断上存在共性问题。",
            "commonProblems": [
                {
                    "title": "属性上下文判断反复出错",
                    "evidence": "涉及6名学生、9次错误作答",
                    "studentCount": 6,
                    "questionIds": ["gq-not-in-evidence"],
                    "teacherAction": "下次课先复盘属性上下文，再安排10分钟随堂练习。",
                }
            ],
        }

        with self.assertRaises(ValueError):
            validate_teaching_class_analysis_payload(payload, {"gq-1", "gq-2"})

    def test_teaching_class_analysis_accepts_evidence_backed_common_problem(self):
        payload = {
            "overallComment": "本班在输出上下文判断上存在共性问题。",
            "commonProblems": [
                {
                    "title": "属性上下文判断反复出错",
                    "evidence": "涉及6名学生、9次错误作答",
                    "studentCount": 6,
                    "questionIds": ["gq-1"],
                    "teacherAction": "下次课先复盘属性上下文，再安排10分钟随堂练习。",
                }
            ],
        }

        result = validate_teaching_class_analysis_payload(payload, {"gq-1", "gq-2"})

        self.assertEqual(result["commonProblems"][0]["questionIds"], ["gq-1"])

    def test_build_class_ai_input_uses_class_scope(self):
        class_data = {
            "classId": 232,
            "items": [
                {
                    "className": "网络安全232班",
                    "overallScore": 60,
                    "knowledgeMasteryScore": 80,
                    "troubleshootingScore": 45,
                    "autonomyScore": 55,
                    "aiCollaborationScore": 75,
                    "engagementScore": 50,
                    "averageTrainingScore": 66,
                    "generatedQuestionAttemptCount": 2,
                    "trainingQuestionSubmitCount": 1,
                    "lastActiveAt": "2026-07-09T10:00:00",
                },
                {
                    "className": "网络安全232班",
                    "overallScore": 72,
                    "knowledgeMasteryScore": 90,
                    "troubleshootingScore": 65,
                    "autonomyScore": 62,
                    "aiCollaborationScore": 82,
                    "engagementScore": 68,
                    "averageTrainingScore": 70,
                    "generatedQuestionAttemptCount": 3,
                    "trainingQuestionSubmitCount": 2,
                },
            ],
        }

        result = build_class_ai_input(class_data)

        self.assertEqual(result["scope"], "class")
        self.assertEqual(result["className"], "网络安全232班")
        self.assertEqual(result["studentCount"], 2)
        self.assertEqual(result["weakDimensions"][0]["dimension"], "troubleshooting")
        self.assertIn("不包含单个学生干预建议", result["sourceLimit"])

    def test_class_rule_fallback_analysis_has_class_actions(self):
        class_data = {
            "classId": 232,
            "items": [
                {
                    "knowledgeMasteryScore": 80,
                    "troubleshootingScore": 45,
                    "autonomyScore": 55,
                    "aiCollaborationScore": 75,
                    "engagementScore": 50,
                }
            ],
        }

        result = build_class_rule_fallback_analysis(class_data, generated_at="2026-07-09T10:00:00")

        self.assertEqual(result["scope"], "class")
        self.assertTrue(result["fallbackUsed"])
        self.assertIn("inClassAction", result["suggestions"][0])
        self.assertIn("afterClassFollowUp", result["suggestions"][0])

    def test_validate_class_ai_analysis_payload_accepts_class_suggestion(self):
        payload = {
            "overallComment": "该班级排障能力均分偏低，课堂需要安排一次共性排查流程训练。",
            "suggestions": [
                {
                    "dimension": "troubleshooting",
                    "label": "排障能力",
                    "averageScore": 52.5,
                    "affectedStudentCount": 4,
                    "evidence": "班级排障能力均分为 52.5 分，4 名学生低于 70 分。",
                    "inClassAction": "建议教师用一题多错的方式讲解错误日志阅读、定位路径记录和修复依据说明。",
                    "afterClassFollowUp": "建议课后收集低分学生的复盘单，检查是否写清报错来源、定位过程和验证结果。",
                    "priority": "high",
                }
            ],
        }

        result = validate_class_ai_analysis_payload(payload)

        self.assertEqual(result["scope"], "class")
        self.assertEqual(result["generatedBy"], "llm")
        self.assertFalse(result["fallbackUsed"])
        self.assertEqual(result["suggestions"][0]["priority"], "high")

    def test_build_student_ai_input_includes_personal_signals(self):
        profile_data = {
            "userId": 3,
            "latestProfile": {
                "overall_score": 59.8,
                "knowledge_mastery_score": 88,
                "troubleshooting_score": 15,
                "autonomy_score": 52,
                "ai_collaboration_score": 83.9,
                "engagement_score": 49.4,
            },
            "dashboard": {"userStats": {"completedCourses": 0, "totalScore": 20, "activeStreak": 1}},
            "recentAttempts": [{"title": "SQL 注入训练", "score": 40, "isCorrect": False}],
            "personalSignals": [
                {
                    "eventType": "ERROR_EVENT",
                    "eventTime": "2026-07-09T10:00:00",
                    "summary": "出现语法类错误，错误特征为 syntax_error",
                    "severity": "medium",
                    "errorCategory": "syntax",
                }
            ],
        }

        result = build_student_ai_input(profile_data)

        self.assertEqual(result["scope"], "student")
        self.assertEqual(result["personalSignalCount"], 1)
        self.assertEqual(result["personalSignals"][0]["eventType"], "ERROR_EVENT")
        self.assertIn("个人错误或求助信号", result["sourceLimit"])

    def test_build_student_ai_input_does_not_forward_raw_signal_content_or_identity_fields(self):
        profile_data = _profile_data()
        profile_data.update(
            {
                "studentName": "张三",
                "studentNumber": "20260001",
                "phone": "13800000000",
                "email": "student@example.com",
                "classAverageScore": 72.5,
                "personalSignals": [
                    {
                        "eventType": "AI_INTERACTION",
                        "eventTime": "2026-07-09T10:00:00",
                        "summary": "原始 AI 对话全文和 token 不得外传",
                        "severity": "low",
                    },
                    {
                        "eventType": "ERROR_EVENT",
                        "eventTime": "2026-07-09T10:05:00",
                        "summary": "cat /etc/passwd && curl secret.example",
                        "severity": "medium",
                        "errorCategory": "syntax",
                    },
                ],
            }
        )

        result = build_student_ai_input(profile_data)
        serialized = json.dumps(result, ensure_ascii=False)

        for forbidden in (
            "张三",
            "20260001",
            "13800000000",
            "student@example.com",
            "classAverageScore",
            "原始 AI 对话全文",
            "cat /etc/passwd",
            "secret.example",
        ):
            self.assertNotIn(forbidden, serialized)
        self.assertEqual(result["personalSignals"][0]["summary"], "记录到个人 AI 求助")
        self.assertEqual(result["personalSignals"][1]["summary"], "个人错误类型：syntax")

    def test_rule_fallback_analysis_uses_student_scope(self):
        profile_data = {
            "latestProfile": {
                "knowledge_mastery_score": 88,
                "troubleshooting_score": 15,
                "autonomy_score": 52,
                "ai_collaboration_score": 83.9,
                "engagement_score": 49.4,
                "computed_at": "2026-04-27T10:53:00",
            },
            "recentAttempts": [
                {"score": 40, "isCorrect": False},
                {"score": 78, "isCorrect": True},
            ],
        }

        result = build_rule_fallback_analysis(profile_data, generated_at="2026-07-06T10:00:00")

        self.assertEqual(result["scope"], "student")
        self.assertEqual(result["generatedBy"], "rule_fallback")
        self.assertTrue(result["fallbackUsed"])
        self.assertIn("AI 分析暂不可用", result["overallComment"])
        self.assertEqual(result["focusAreas"][0]["dimension"], "troubleshooting")
        self.assertNotIn("班级", result["focusAreas"][0]["teacherAction"])

    def test_validate_ai_analysis_payload_rejects_student_tone(self):
        invalid_payload = {
            "overallComment": "该学生需要关注排障能力。",
            "focusAreas": [
                {
                    "dimension": "troubleshooting",
                    "label": "排障能力",
                    "score": 15,
                    "evidence": "个人五维得分较低。",
                    "teacherAction": "你应该开始训练排障题目。",
                    "priority": "high",
                }
            ],
        }

        with self.assertRaises(ValueError):
            validate_ai_analysis_payload(invalid_payload)

    def test_validate_ai_analysis_payload_rejects_vague_teacher_action(self):
        invalid_payload = {
            "overallComment": "该学生排障能力较弱，需要教师安排个人复盘。",
            "focusAreas": [
                {
                    "dimension": "troubleshooting",
                    "label": "排障能力",
                    "score": 15,
                    "evidence": "个人五维得分显示排障能力明显低于其他维度。",
                    "teacherAction": "建议加强训练，提升相关能力。",
                    "priority": "high",
                }
            ],
        }

        with self.assertRaises(ValueError):
            validate_ai_analysis_payload(invalid_payload)

    def test_validate_ai_analysis_payload_rejects_missing_score(self):
        invalid_payload = {
            "overallComment": "该学生排障能力较弱，需要教师安排个人复盘。",
            "focusAreas": [
                {
                    "dimension": "troubleshooting",
                    "label": "排障能力",
                    "evidence": "个人五维得分显示排障能力明显低于其他维度。",
                    "teacherAction": "建议教师安排一次错误定位复盘，要求学生说明报错来源、定位路径和修复依据。",
                    "priority": "high",
                }
            ],
        }

        with self.assertRaises(ValueError):
            validate_ai_analysis_payload(invalid_payload)

    def test_validate_ai_analysis_payload_accepts_teacher_action(self):
        payload = {
            "overallComment": "该学生排障能力较弱，需要教师安排个人复盘。",
            "focusAreas": [
                {
                    "dimension": "troubleshooting",
                    "label": "排障能力",
                    "score": 15,
                    "evidence": "个人五维得分显示排障能力为 15.0 分。",
                    "teacherAction": "建议教师安排一次错误定位复盘，要求学生说明报错来源、定位路径和修复依据。",
                    "priority": "high",
                }
            ],
        }

        result = validate_ai_analysis_payload(payload)

        self.assertEqual(result["scope"], "student")
        self.assertEqual(result["generatedBy"], "llm")
        self.assertFalse(result["fallbackUsed"])
        self.assertEqual(result["focusAreas"][0]["priority"], "high")

class ManualStudentAnalysisTest(unittest.IsolatedAsyncioTestCase):
    async def test_provider_failure_does_not_return_rule_fallback(self):
        repository = TeacherStudentAnalysisRepository(memory_store={})
        current_user = {"user_id": 7, "role": "teacher"}
        with (
            patch("teacher_ai_analysis_service.STUDENT_ANALYSIS_REPOSITORY", repository),
            patch("teacher_ai_analysis_service.require_student_in_owned_teaching_class"),
            patch(
                "teacher_ai_analysis_service.get_student_profile_for_teacher",
                return_value=_profile_data(),
            ),
            patch(
                "teacher_ai_analysis_service._call_llm_for_student_analysis",
                new=AsyncMock(side_effect=RuntimeError("provider unavailable")),
            ),
        ):
            with self.assertRaises(TeacherAnalysisProviderError):
                await run_manual_student_analysis(101, 3, current_user=current_user)

        latest = repository.get_latest(7, 101, 3)
        self.assertEqual("IDLE", latest["analysisStatus"])
        self.assertIsNone(latest["analysis"])

    async def test_selected_class_is_used_for_student_evidence(self):
        repository = TeacherStudentAnalysisRepository(memory_store={})
        current_user = {"user_id": 7, "role": "teacher"}
        with (
            patch("teacher_ai_analysis_service.STUDENT_ANALYSIS_REPOSITORY", repository),
            patch("teacher_ai_analysis_service.require_student_in_owned_teaching_class"),
            patch(
                "teacher_ai_analysis_service.get_student_profile_for_teacher",
                return_value=_profile_data(),
            ) as profile_loader,
            patch(
                "teacher_ai_analysis_service._call_llm_for_student_analysis",
                new=AsyncMock(return_value=_valid_ai_payload()),
            ),
        ):
            result = await run_manual_student_analysis(101, 3, current_user=current_user)

        profile_loader.assert_called_once_with(
            3,
            current_user=current_user,
            teaching_class_id=101,
        )
        self.assertEqual("READY", result["analysisStatus"])
        self.assertEqual("llm", result["analysis"]["generatedBy"])
        self.assertFalse(result["analysis"]["fallbackUsed"])


class LlmClientIntegrationTest(unittest.IsolatedAsyncioTestCase):
    async def _generate_with_chat_json(self, *, payload=None, side_effect=None):
        chat_json = AsyncMock(side_effect=side_effect, return_value=payload)
        with (
            patch(
                "teacher_ai_analysis_service.get_student_profile_for_teacher",
                return_value=_profile_data(),
            ),
            patch("llm_client.chat_json", new=chat_json),
        ):
            return await generate_teacher_student_ai_analysis(3)

    async def test_analysis_uses_llm_client_chat_json(self):
        chat_json = AsyncMock(return_value=_valid_ai_payload())
        with (
            patch(
                "teacher_ai_analysis_service.get_student_profile_for_teacher",
                return_value=_profile_data(),
            ),
            patch("llm_client.chat_json", new=chat_json),
        ):
            result = await generate_teacher_student_ai_analysis(3)

        chat_json.assert_awaited_once()
        self.assertEqual(result["overallComment"], _valid_ai_payload()["overallComment"])
        self.assertEqual(result["generatedBy"], "llm")
        self.assertFalse(result["fallbackUsed"])

    async def test_provider_http_error_uses_rule_fallback(self):
        result = await self._generate_with_chat_json(
            side_effect=RuntimeError("LLM HTTP 400: bad request")
        )

        self.assertTrue(result["fallbackUsed"])
        self.assertEqual(result["generatedBy"], "rule_fallback")

    async def test_empty_answer_uses_rule_fallback(self):
        result = await self._generate_with_chat_json(side_effect=ValueError("空回答"))

        self.assertTrue(result["fallbackUsed"])

    async def test_non_json_answer_uses_rule_fallback(self):
        result = await self._generate_with_chat_json(
            side_effect=ValueError("回答中未找到合法 JSON")
        )

        self.assertTrue(result["fallbackUsed"])

    async def test_missing_required_field_uses_rule_fallback(self):
        invalid = _valid_ai_payload()
        del invalid["focusAreas"][0]["teacherAction"]

        result = await self._generate_with_chat_json(payload=invalid)

        self.assertTrue(result["fallbackUsed"])

    async def test_student_tone_uses_rule_fallback(self):
        invalid = _valid_ai_payload()
        invalid["focusAreas"][0]["teacherAction"] = "你应该开始训练排障题目。"

        result = await self._generate_with_chat_json(payload=invalid)

        self.assertTrue(result["fallbackUsed"])

    async def test_vague_advice_uses_rule_fallback(self):
        invalid = _valid_ai_payload()
        invalid["focusAreas"][0]["teacherAction"] = "建议加强训练，提升相关能力。"

        result = await self._generate_with_chat_json(payload=invalid)

        self.assertTrue(result["fallbackUsed"])

    async def test_invalid_dimension_uses_rule_fallback(self):
        invalid = _valid_ai_payload()
        invalid["focusAreas"][0]["dimension"] = "class_average"

        result = await self._generate_with_chat_json(payload=invalid)

        self.assertTrue(result["fallbackUsed"])


if __name__ == "__main__":
    unittest.main()

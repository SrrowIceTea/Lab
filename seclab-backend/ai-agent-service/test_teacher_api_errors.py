import unittest
from unittest.mock import AsyncMock, MagicMock, patch

import httpx

import main
from teacher_ai_analysis_service import provider_failure_message


class TeacherApiErrorTest(unittest.TestCase):
    def test_experiment_risk_routes_are_registered_without_teacher_id_parameters(self):
        paths = {route.path for route in main.app.routes}

        self.assertIn(
            "/api/teacher/teaching-classes/{class_id}/experiments/{course_id}/knowledge-risks",
            paths,
        )
        self.assertIn(
            "/api/teacher/teaching-classes/{class_id}/experiments/{course_id}/knowledge-risks/{knowledge_point_id}",
            paths,
        )
        self.assertIn(
            "/api/teacher/teaching-classes/{class_id}/experiments/{course_id}/knowledge-points/{knowledge_point_id}/ai-analysis",
            paths,
        )
        self.assertIn(
            "/api/teacher/teaching-classes/{class_id}/knowledge-exercises/{exercise_id}",
            paths,
        )
        self.assertIn(
            "/api/teacher/teaching-classes/{class_id}/knowledge-exercises/{exercise_id}/review",
            paths,
        )
        self.assertIn(
            "/api/teacher/teaching-classes/{class_id}/knowledge-exercises/{exercise_id}/regenerate",
            paths,
        )

    def test_teacher_auth_loads_owned_teaching_classes(self):
        connection = _FakeConnection(
            user={
                "user_id": 7,
                "user_student_number": "teacher01",
                "user_name": "王老师",
                "is_deleted": 0,
                "user_role": "TEACHER",
            },
            classes=[{"teaching_class_id": 101}, {"teaching_class_id": 103}],
        )
        with patch.object(main, "get_connection", return_value=connection):
            context = main._load_teacher_auth_context(7)

        self.assertEqual(context["role"], "teacher")
        self.assertEqual(context["owned_teaching_class_ids"], [101, 103])
        self.assertEqual(context["scope_class_ids"], [])
        self.assertEqual(connection.cursor_instance.execute_count, 2)

    def test_internal_exception_does_not_leak_details(self):
        error = main._teacher_repo_error(RuntimeError("database password leaked"))

        self.assertEqual(error.status_code, 500)
        self.assertEqual(error.detail, "数据加载失败，请重新加载。")
        self.assertNotIn("password", str(error.detail))

    def test_permission_and_missing_data_are_controlled(self):
        forbidden = main._teacher_repo_error(PermissionError("student outside teacher scope"))
        missing = main._teacher_repo_error(KeyError("classId does not exist: 999"))

        self.assertEqual((forbidden.status_code, forbidden.detail), (403, "当前账号无权查看该数据。"))
        self.assertEqual((missing.status_code, missing.detail), (404, "请求的数据已不存在或无权访问。"))

    def test_provider_format_failure_returns_a_useful_business_status(self):
        error = main._teacher_repo_error(
            main.TeacherAnalysisProviderError(
                "大模型已返回内容，但结果格式不符合教学分析要求，请检查提示词和输出格式。"
            )
        )

        self.assertEqual(error.status_code, 503)
        self.assertEqual(
            error.detail,
            "本次智能分析未生成可用结论，当前仍显示上次成功结果；原始作答统计不受影响，请稍后重试。",
        )
        self.assertNotIn("Dify", error.detail)
        self.assertNotIn("Agent", error.detail)
        self.assertNotIn("格式", error.detail)

    def test_student_assignment_scope_accepts_self_and_rejects_another_student(self):
        context = {"user_id": 261, "role": "student"}

        main._require_student_self(context, 261)
        with self.assertRaises(main.HTTPException) as raised:
            main._require_student_self(context, 262)

        self.assertEqual(raised.exception.status_code, 403)

    def test_teacher_assignment_training_request_tracks_intervention_and_knowledge(self):
        payload = main._build_teacher_assignment_training_request(
            261,
            {
                "interventionId": 17,
                "knowledgePointName": "SQL盲注",
            },
        )

        self.assertEqual(payload["user_id"], 261)
        self.assertEqual(payload["recommendation_id"], "intervention-17")
        self.assertEqual(payload["knowledge_tags"], ["SQL盲注"])
        self.assertEqual(payload["source"], "teacher_assignment")
        self.assertEqual(payload["count"], 5)

    def test_intervention_request_carries_approved_exercise_scope(self):
        request = main.TeacherInterventionCreateRequest(
            title="联合查询专项练习",
            actionType="TARGETED_PRACTICE",
            studentIds=[261, 262],
            courseId=7,
            knowledgePointId=71,
            approvedExerciseIds=[31, 32],
        )

        self.assertEqual(request.courseId, 7)
        self.assertEqual(request.approvedExerciseIds, [31, 32])


class AiAnalysisHealthTest(unittest.IsolatedAsyncioTestCase):
    async def test_missing_llm_configuration_is_reported_without_secret_values(self):
        with patch.object(main.llm_client, "is_configured", return_value=False):
            result = await main._probe_llm_configuration()

        self.assertEqual(
            result,
            {
                "configured": False,
                "providerReachable": False,
                "message": "大模型尚未配置，请设置 LLM_API_BASE / LLM_API_KEY / LLM_MODEL。",
            },
        )

    async def test_configured_llm_is_probed_through_chat_completions_endpoint(self):
        response = MagicMock()
        response.raise_for_status.return_value = None
        client = AsyncMock()
        client.__aenter__.return_value = client
        client.__aexit__.return_value = False
        client.post.return_value = response

        with (
            patch.object(main.llm_client, "is_configured", return_value=True),
            patch.object(main.config, "LLM_API_BASE", "https://api.llm.example/v1"),
            patch.object(main.config, "LLM_API_KEY", "secret-key"),
            patch.object(main.config, "LLM_MODEL", "test-model"),
            patch.object(main.httpx, "AsyncClient", return_value=client),
        ):
            result = await main._probe_llm_configuration()

        self.assertTrue(result["configured"])
        self.assertTrue(result["providerReachable"])
        self.assertEqual(result["message"], "大模型接口连接正常。")
        self.assertEqual(result["provider"], "https://api.llm.example/v1")
        self.assertEqual(result["model"], "test-model")
        client.post.assert_awaited_once()
        call_args, call_kwargs = client.post.await_args
        self.assertEqual(call_args[0], "https://api.llm.example/v1/chat/completions")
        self.assertEqual(call_kwargs["headers"]["Authorization"], "Bearer secret-key")

    async def test_llm_probe_failure_returns_safe_message(self):
        client = AsyncMock()
        client.__aenter__.return_value = client
        client.__aexit__.return_value = False
        client.post.side_effect = httpx.ConnectError("connection failed")

        with (
            patch.object(main.llm_client, "is_configured", return_value=True),
            patch.object(main.config, "LLM_API_BASE", "https://api.llm.example/v1"),
            patch.object(main.httpx, "AsyncClient", return_value=client),
        ):
            result = await main._probe_llm_configuration()

        self.assertEqual(result["configured"], True)
        self.assertEqual(result["providerReachable"], False)
        self.assertEqual(result["message"], "大模型已配置，但当前无法连接。")


class AiAnalysisProviderFailureTest(unittest.TestCase):
    def test_timeout_is_reported_as_generation_timeout_not_missing_configuration(self):
        message = provider_failure_message(TimeoutError("stream stalled"))

        self.assertIn("生成超时", message)
        self.assertIn("额度", message)
        self.assertNotIn("尚未配置", message)

    def test_rate_limit_is_reported_as_quota_or_rate_limit(self):
        request = httpx.Request("POST", "https://api.llm.example/v1/chat/completions")
        response = httpx.Response(429, request=request)
        message = provider_failure_message(httpx.HTTPStatusError("rate limited", request=request, response=response))

        self.assertIn("额度或调用频率", message)


class _FakeCursor:
    def __init__(self, user, classes):
        self.user = user
        self.classes = classes
        self.execute_count = 0

    def __enter__(self):
        return self

    def __exit__(self, *_args):
        return False

    def execute(self, *_args, **_kwargs):
        self.execute_count += 1

    def fetchone(self):
        return self.user

    def fetchall(self):
        return self.classes


class _FakeConnection:
    def __init__(self, user, classes):
        self.cursor_instance = _FakeCursor(user, classes)

    def __enter__(self):
        return self

    def __exit__(self, *_args):
        return False

    def cursor(self):
        return self.cursor_instance


if __name__ == "__main__":
    unittest.main()

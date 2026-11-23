# 本地 RAG 与大模型配置说明（已移除 Dify）

本项目的 AI 能力由**本地 Agent + 外部大模型 API**提供，不再依赖 Dify 平台。

## 一、大模型配置（OpenAI Chat Completions 兼容）

在 `ai-agent-service/.env` 中配置（参考 `.env.example`）：

```env
LLM_API_BASE=https://api.deepseek.com/v1
LLM_API_KEY=你的密钥
LLM_MODEL=deepseek-chat
```

支持任何提供 `/chat/completions` 的服务：DeepSeek、通义千问（DashScope 兼容端点）、OpenAI、本地 vLLM / Ollama 等。

可选参数：
- `LLM_TIMEOUT=120` 超时秒数
- `LLM_TEMPERATURE=0.3` 生成温度
- `LLM_MAX_TOKENS=2048`
- `LLM_GUIDANCE_MODEL=` 主动提示单独指定模型，留空则用 LLM_MODEL
- `ENABLE_FAKE_LLM_FOR_TEST=false` 无真实 API 时置 true 用本地假回复联调

健康检查：`GET /health/ai-analysis` 返回是否配置、接口是否可达、当前模型。

## 二、RAG 实现（完全本地）

RAG 检索**不依赖任何外部平台**，全部在后端本地完成：

| 数据源 | 代码 | 用途 |
|---|---|---|
| `seclab_profile.module_knowledge_point` / `knowledge_point` | `knowledge_repository.py` | 课程知识点（按 moduleId/courseId/tag 检索） |
| `seclab_profile.generated_question` + `standard_questions.json` | `standard_question_repository.py` | 规范题目样例（按标签/题型/难度/模块打分排序，top_k=3） |

配置项：
- `RAG_MODE=local|hybrid|api`（默认 local）
  - `local`：只用本地检索结果
  - `hybrid`：本地检索 + 模型自由发挥
  - `api`：保留枚举，当前不做远程检索
- `ENABLE_LOCAL_RAG=true` 是否启用本地检索
- `STRICT_SOURCE_EXAMPLE_VALIDATION=false` 严格来源校验

## 三、对话前注入课程上下文（新能力）

学生打开课程实践页后，前端会把当前学习情境随 `/api/chat` 请求发送：

```json
{
  "query": "学生的问题",
  "terminal_log": "模拟终端最近输出",
  "lab_context": {
    "moduleId": 3,
    "moduleName": "第3讲 语言与机器的火花碰撞",
    "courseId": 3,
    "currentTask": "任务一：分词、词向量与言外之意",
    "labSessionId": "...",
    "questions": [
      {"id": 3001, "type": "single-choice", "content": "...", "options": [...], "score": 10}
    ],
    "objectives": ["..."]
  }
}
```

后端 `course_context.py` 把它拼进 system prompt，AI 在回答前就知道：

1. 学生正在学哪一讲、哪个任务点
2. 本节有哪些题目、题型、分值、解析要点
3. 学习目标与本地 RAG 检索到的知识点

AI 被明确要求：结合题目引导、不直接报答案、基于终端日志给具体下一步建议。

## 四、SSE 事件契约（保持不变）

`/api/chat` 仍输出前端既有事件：

```json
{"event": "message", "answer": "...", "conversation_id": "..."}
{"event": "message_end", "conversation_id": "...", "message_id": "..."}
{"event": "error", "message": "..."}
```

主动提示 `/api/guidance/stream/{id}` 事件：`ready` / `guidance_start` / `chunk` / `error` / `guidance_end`，字段保持不变。

## 五、验收清单

- [ ] 配置 `.env` 后 `GET /health/ai-analysis` 返回 `configured: true`、`providerReachable: true`
- [ ] 进入任一课程实践页，打开 AI 助手，提问"这节课在学什么"——应能准确说出课程名与任务
- [ ] 提问"第一题怎么做"——应给提示而非直接报答案
- [ ] 在模拟终端运行几条命令后点"一键提示"——应基于日志给出具体建议
- [ ] 教师端 AI 分析在 LLM 不可用时自动走规则兜底，不返回 500

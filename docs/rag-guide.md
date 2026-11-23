# 课程资料 RAG 使用说明

教师上传课程资料 → 平台切块并向量化 → 学生在该课程的 AI 助手里提问时自动检索并引用。

## 1. 原理与存储

```
教师端「课程资料」上传 .pdf/.docx/.md/.txt
        ↓  文本提取（pypdf / python-docx）
        ↓  切块：500 字 / 重叠 80 字
        ↓  SiliconFlow Qwen/Qwen3-Embedding-8B 生成向量（1024 维）
   MySQL  document_source（文件元信息）
           document_chunk（文本块 + embedding_json 向量数组）
        ↓
学生端课程页提问 → 问题向量化 → numpy 余弦相似度取 Top 3
        ↓  相关度 ≥ 0.35 的片段拼进 system prompt
        ↓  AI 回答时优先依据资料，并标注「已参考本课程资料 N 段」
```

**没有引入向量数据库**：几百份文档、几千个文本块时，在应用层用 numpy 算余弦是毫秒级；
MySQL JSON 存向量足够。等单课程超过十万块再考虑 Milvus/Qdrant，接口层已隔离，替换只改
`document_rag_service.search()`。

## 2. 启用（三步）

1. 打开 `seclab-backend/ai-agent-service/.env`，填写硅基流动 Key：

   ```ini
   EMBEDDING_API_KEY=sk-你的硅基流动Key
   ```

   Key 在 <https://cloud.siliconflow.cn/account/ak> 生成。模型与维度默认已配好：

   ```ini
   EMBEDDING_API_BASE=https://api.siliconflow.cn/v1
   EMBEDDING_MODEL=Qwen/Qwen3-Embedding-8B
   EMBEDDING_DIMENSIONS=1024
   ```

2. 打开教师端「课程资料」页，点 **重新加载配置**（会重读 `.env`，**不需要重启 AI 服务**）。
   状态灯变绿表示已读到 Key。

3. 点 **测试连接**。看到「连接正常 · 1024 维 · xxx ms」说明 Key、网络、维度全部正常。

## 3. 演示流程

1. 教师账号登录（`admin / 123456`）→ 左侧「课程资料」→ 选择课程 → 上传一份讲义 PDF。
   列表出现「已就绪」且文本块数量 > 0 即入库成功。
2. 学生账号登录（`123456 / 123456`）→ 进入同一门课的课程页 → 右下角 AI 助手提问。
   回答气泡下方出现「已参考本课程资料 N 段」，说明命中了教师上传的资料。
3. 想验证检索质量，可直接调接口：

   ```bash
   curl -X POST http://localhost:8010/api/rag/search \
     -H "Authorization: Bearer <用户token>" \
     -F "courseId=12" -F "query=什么是监督学习"
   ```

## 4. 参数调整

| 变量 | 默认 | 说明 |
| --- | --- | --- |
| `DOC_CHUNK_SIZE` | 500 | 每块字符数，讲义小可调到 800 |
| `DOC_CHUNK_OVERLAP` | 80 | 块间重叠，避免切断上下文 |
| `DOC_TOP_K` | 3 | 注入对话的片段数，越大越全但更耗 token |
| `EMBEDDING_DIMENSIONS` | 1024 | Qwen3-8B 支持降维，1024 足够且省存储 |
| `ENABLE_DOCUMENT_RAG` | true | 关闭后对话不再检索文档 |

改了这些值同样只需点「重新加载配置」。

## 5. 排错

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| 状态灯黄、提示未配置 | `.env` 没读到 Key | 确认写在 `ai-agent-service/.env`，不是 `.env.example`；点重新加载 |
| 测试连接报 401 / invalid token | Key 错误或已删除 | 重新生成 Key |
| 测试连接报维度不一致 | `EMBEDDING_DIMENSIONS` 与实际返回不符 | 改回 1024 或与接口一致 |
| 测试连接超时 | 网络不通 / 限流 | 检查代理；429 时等额度重置 |
| 上传后状态「失败」 | PDF 是扫描件（无文字层）或加密 | 换文字版 PDF，或先另存为 .docx/.txt |
| 学生端没有「已参考资料」 | 课程不匹配或相关度都 < 0.35 | 确认学生所在课程 = 上传资料的课程；换个更贴近资料的问题 |
| 上传报 20MB 限制 | 单文件过大 | 拆分上传 |

## 6. 接口清单

| 方法 | 路径 | 权限 | 说明 |
| --- | --- | --- | --- |
| GET | `/api/rag/config` | 公开 | 查看是否已配置（不返回 Key） |
| POST | `/api/rag/config/reload` | 教师 | 重读 `.env` 的向量化配置 |
| POST | `/api/rag/test` | 教师 | 真实调用一次 embedding 自检 |
| GET | `/api/rag/documents?courseId=` | 教师 | 资料列表 |
| POST | `/api/rag/documents` | 教师 | 上传（multipart：courseId + file） |
| DELETE | `/api/rag/documents/{sourceId}` | 教师 | 删除资料及其向量块 |
| POST | `/api/rag/search` | 登录用户 | 检索调试（courseId + query） |

数据结构：`document_source` 一文件一行，`document_chunk` 一块一行，外键级联删除。

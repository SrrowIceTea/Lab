import os

from dotenv import load_dotenv

load_dotenv()

# ── 本地 Agent / 外部大模型（OpenAI Chat Completions 兼容）──────────
# 任意兼容 /v1/chat/completions 的服务均可：DeepSeek、通义、OpenAI、本地 vLLM 等
LLM_API_BASE = os.getenv("LLM_API_BASE", "https://api.deepseek.com/v1")
LLM_API_KEY = os.getenv("LLM_API_KEY", "")
LLM_MODEL = os.getenv("LLM_MODEL", "deepseek-chat")
LLM_TIMEOUT = int(os.getenv("LLM_TIMEOUT", "120"))
LLM_TEMPERATURE = float(os.getenv("LLM_TEMPERATURE", "0.3"))
LLM_MAX_TOKENS = int(os.getenv("LLM_MAX_TOKENS", "2048"))
LLM_GUIDANCE_MODEL = os.getenv("LLM_GUIDANCE_MODEL", "")
ENABLE_FAKE_LLM_FOR_TEST = os.getenv("ENABLE_FAKE_LLM_FOR_TEST", "false")

# RAG（供应商无关）：local 本地检索 / hybrid 本地+题目样例 / api 预留外部检索
RAG_MODE = os.getenv("RAG_MODE", "local")
ENABLE_LOCAL_RAG = os.getenv("ENABLE_LOCAL_RAG", "true").lower() in ("true", "1", "yes")
STRICT_SOURCE_EXAMPLE_VALIDATION = os.getenv(
    "STRICT_SOURCE_EXAMPLE_VALIDATION", "false"
).lower() in ("true", "1", "yes")

# 兼容旧配置：若仍有人设置 DIFY_*，映射到通用配置（过渡期用）
if not LLM_API_KEY and os.getenv("DIFY_API_KEY"):
    LLM_API_KEY = os.getenv("DIFY_API_KEY", "")
    if not os.getenv("LLM_API_BASE") and os.getenv("DIFY_API_URL"):
        LLM_API_BASE = os.getenv("DIFY_API_URL", "")

# AI agent service listener
SERVICE_HOST = os.getenv("SERVICE_HOST", "0.0.0.0")
SERVICE_PORT = int(os.getenv("SERVICE_PORT", "8010"))

# Frontend CORS allowlist
DEFAULT_CORS_ORIGINS = [
    "http://localhost:5173",
    "http://127.0.0.1:5173",
    "http://localhost:5174",
    "http://127.0.0.1:5174",
    "http://localhost:5175",
    "http://127.0.0.1:5175",
    "http://localhost:80",
    "http://127.0.0.1:80",
    "http://localhost",
    "http://127.0.0.1",
    "http://192.168.1.106:5173",
]

configured_cors_origins = [
    origin.strip()
    for origin in os.getenv("CORS_ORIGINS", "").split(",")
    if origin.strip()
]

CORS_ORIGINS = list(dict.fromkeys(configured_cors_origins + DEFAULT_CORS_ORIGINS))

# Docker tool container name allowlist
# 前缀需与靶场目录名保持一致，例如 command-inject/ 目录对应容器 command-inject-web-1
# 注意：不要使用 cmd 这种简写，cmd 既不是 command-inject 的前缀也不是子串，会导致白名单误拒
ALLOWED_CONTAINER_PREFIXES = os.getenv(
    "ALLOWED_CONTAINER_PREFIXES",
    "sqli,xss,csrf,upload,dir,command-inject,sec-code,stack-overflow,protocol-analysis,heap-overflow,format-string",
).split(",")

# Maximum log lines returned by Docker tools
MAX_LOG_LINES = int(os.getenv("MAX_LOG_LINES", "200"))

# MySQL persistence for learning events and profile snapshots
MYSQL_HOST = os.getenv("MYSQL_HOST", "localhost")
MYSQL_PORT = int(os.getenv("MYSQL_PORT", "3306"))
MYSQL_USER = os.getenv("MYSQL_USER", "seclab_app")
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD", "Seclab@123")
MYSQL_DATABASE = os.getenv("MYSQL_DATABASE", "seclab_profile")
MYSQL_CHARSET = os.getenv("MYSQL_CHARSET", "utf8mb4")

# ── 操作环境（per-student noVNC 桌面）配置 ──────────────────
# 与 operation_env.py / operation_session_repository.py 配合使用：
# ai-agent-service 动态启动 operation 容器（5901 映射到随机宿主端口），
# 并通过 /api/docker/vnc/{session_id} WebSocket 把浏览器与容器 VNC 桥接起来。
OPERATION_IMAGE = os.getenv("OPERATION_IMAGE", "seclab-op-web-tools:1.0")
OPERATION_VNC_PASSWORD = os.getenv("OPERATION_VNC_PASSWORD", "123456")
OPERATION_VNC_HOST = os.getenv("OPERATION_VNC_HOST", "127.0.0.1")
OPERATION_SESSION_TIMEOUT_SECONDS = int(os.getenv("OPERATION_SESSION_TIMEOUT_SECONDS", str(2 * 60 * 60)))
OPERATION_CLEANUP_INTERVAL_SECONDS = int(os.getenv("OPERATION_CLEANUP_INTERVAL_SECONDS", str(10 * 60)))

# 静态映射：模块 baseId -> 需要加入操作桌面会话网络的靶机容器名。
# baseId 由前端 getBaseLabId() 推导（module_id >= 100 取首位数字，否则原值），
# 与 SecLab-FrontEnd-2/src/pages/User/Module/index.vue:getBaseLabId() 保持一致。
OPERATION_TARGET_CONTAINERS = {
    1: ["sqli-lab-web-1"],
    2: ["xss-lab-web-1"],
    3: ["csrf-lab-web-1"],
    4: ["command-inject-web-1"],
    5: ["file-upload-lab-web-1"],
    6: ["directory-traversal-lab-web-1"],
    15: ["stack-overflow-lab-web-1"],  # 栈溢出 pwn 靶机（TCP:70）
}

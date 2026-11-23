<template>
  <div class="floating-chat" 
       :class="{ 'minimized': isMinimized, 'maximized': isMaximized }"
       :style="{ right: position.x + 'px', bottom: position.y + 'px' }">
    
    <!-- 拖动条 -->
    <div class="drag-handle" @mousedown="startDragging">
      <div class="flex items-center justify-between w-full px-2">
        <div class="flex items-center gap-2">
          <div class="w-6 h-6 rounded-lg bg-gradient-to-br from-primary to-secondary flex items-center justify-center shadow-sm">
            <i class="fas fa-robot text-xs text-white"></i>
          </div>
          <div v-if="!isMinimized">
            <h3 class="text-sm font-bold"><span class="text-primary">AI</span> <span class="text-secondary">学习助手</span></h3>
          </div>
        </div>
        <div class="flex gap-1">
          <button @click="toggleMinimize" class="btn btn-ghost btn-xs px-1">
            <i :class="isMinimized ? 'fas fa-expand-alt' : 'fas fa-minus'"></i>
          </button>
          <button @click="toggleMaximize" class="btn btn-ghost btn-xs px-1" v-if="!isMinimized">
            <i :class="isMaximized ? 'fas fa-compress-alt' : 'fas fa-expand'"></i>
          </button>
          <button @click="closeChat" class="btn btn-ghost btn-xs px-1 text-error" v-if="!isMinimized">
            <i class="fas fa-times"></i>
          </button>
        </div>
      </div>
    </div>

    <!-- 聊天内容区域 -->
    <div v-if="!isMinimized" class="chat-container">
      <!-- 消息区域 -->
      <div ref="chatContainer" class="messages-container">
        <div v-if="messages.length === 0" class="empty-state">
          <div class="flex flex-col items-center justify-center h-full text-center text-base-content/50 py-4">
            <div class="w-12 h-12 rounded-full bg-gradient-to-br from-primary/20 to-secondary/20 
                      flex items-center justify-center mb-2 animate-pulse">
              <i class="fas fa-robot text-xl text-primary"></i>
            </div>
            <h3 class="text-sm font-bold mb-1">
              AI 学习助手
            </h3>
            <div class="max-w-xs text-xs text-base-content/70 px-2">
              你的 AI 微课学习伙伴，可读取当前课堂终端日志
            </div>
          </div>
        </div>
            
        <template v-else>
          <div
            v-for="(message, index) in messages"
            :key="index"
            class="mb-2" 
          >
            <!-- 用户消息 -->
            <div 
              v-if="message.role === 'user'"
              class="chat chat-end"
            >
              <div class="chat-image avatar">
                <div class="w-6 rounded-full ring ring-primary ring-offset-base-100 ring-offset-1">
                  <img 
                    src="https://api.dicebear.com/7.x/avataaars/svg?seed=user"
                    alt="用户"
                  />
                </div>
              </div>
              <div class="chat-bubble chat-bubble-primary text-xs">
                {{ message.content }}
              </div>
              <div class="chat-footer opacity-50 text-xs">
                <span>{{ formatTime(message.timestamp) }}</span>
              </div>
            </div>

            <!-- AI回复 -->
            <div 
              v-else
              class="chat chat-start"
            >
              <div class="chat-image avatar">
                <div class="w-6 rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center shadow-md">
                  <i class="fas fa-robot text-xs text-white"></i>
                </div>
              </div>
              <div class="chat-bubble assistant-bubble p-0 text-xs">
                <!-- ── Phase 3: proactive guidance 主动提示标记 ─────────── -->
                <div
                  v-if="message.isGuidance"
                  class="px-2 pt-2 pb-1 bg-gradient-to-r from-secondary/15 to-primary/15 border-b border-secondary/20"
                >
                  <div class="flex items-center gap-1.5 text-xs text-secondary font-medium">
                    <i class="fas fa-lightbulb"></i>
                    <span>主动提示</span>
                    <span class="ml-auto text-base-content/50 font-normal">
                      {{ message.trigger_reason === 'repeated_error' ? '重复错误' :
                         message.trigger_reason === 'stuck_loop' ? '卡循环' :
                         message.trigger_reason === 'repeated_command' ? '重复命令' : message.trigger_reason }}
                    </span>
                    <span
                      v-if="message.guidance_status === 'streaming'"
                      class="loading loading-spinner loading-xs text-secondary"
                    ></span>
                  </div>
                </div>
                <!-- ── 工具调用可视化卡片 ─────────────────────── -->
                <div
                  v-if="message.toolCalls && message.toolCalls.length > 0"
                  class="px-2 pt-2 space-y-1"
                >
                  <div
                    v-for="tc in message.toolCalls"
                    :key="tc.id"
                    class="rounded-lg border border-secondary/25 bg-base-200/60 p-2 text-xs"
                  >
                    <!-- 工具名 + 状态 -->
                    <div class="flex items-center gap-1.5 font-medium">
                      <span
                        v-if="tc.status === 'calling'"
                        class="loading loading-spinner loading-xs text-secondary"
                      ></span>
                      <i v-else class="fas fa-check-circle text-success" style="font-size:10px"></i>
                      <span class="text-secondary">
                        {{ TOOL_LABELS[tc.tool] || ('🔧 ' + tc.tool) }}
                      </span>
                      <span class="ml-auto text-base-content/40 font-normal">
                        {{ tc.status === 'calling' ? '调用中…' : '✔ 完成' }}
                      </span>
                    </div>
                    <!-- 参数摘要 -->
                    <div
                      v-if="tc.toolInput"
                      class="mt-1 rounded bg-base-300/50 px-1.5 py-0.5 font-mono text-base-content/50"
                    >
                      {{ tc.toolInput }}
                    </div>
                    <!-- 结果预览（截断） -->
                    <div
                      v-if="tc.observation"
                      class="mt-1 text-base-content/55 leading-snug"
                    >
                      {{ tc.observation.length > 140 ? tc.observation.slice(0, 140) + '…' : tc.observation }}
                    </div>
                  </div>
                </div>

                <!-- ── 思考过程 - 可折叠面板 ─────────────────── -->
                <div v-if="message.thinking && message.showThinking" class="collapse collapse-arrow bg-base-200/30 mb-2 rounded-lg">
                  <input type="checkbox" class="min-h-0" checked />
                  <div class="collapse-title py-1 px-2 min-h-0 flex items-center gap-2 text-base-content/70 text-xs font-medium">
                    <i class="fas fa-brain text-secondary text-xs"></i>
                    <span class="text-xs">思考过程</span>
                  </div>
                  <div class="collapse-content px-2 pt-0">
                    <div class="text-xs text-base-content/70 thinking-content p-2">
                      <div v-if="message.isStreaming">
                        <MarkdownRenderer :content="message.thinking || ''" />
                        <span v-if="message.thinking" class="inline-block ml-1">
                          <span class="loading loading-dots loading-xs"></span>
                        </span>
                      </div>
                      <div v-else>
                        <MarkdownRenderer :content="message.thinking || ''" />
                      </div>
                    </div>
                  </div>
                </div>

                <!-- 回复内容 -->
                <div class="p-2" v-if="message.content || message.streamContent">
                  <div v-if="message.isStreaming">
                    <MarkdownRenderer :content="message.streamContent || ''" />
                  </div>
                  <div v-else>
                    <MarkdownRenderer :content="message.content" />
                  </div>
                </div>
                <div v-else class="flex items-center gap-2 p-2">
                  <span class="loading loading-dots loading-xs"></span>
                  <span class="text-xs">思考中...</span>
                </div>
                <!-- 课程资料引用提示 -->
                <div v-if="message.ragHits" class="rag-cite">
                  <i class="fas fa-book-open"></i>
                  已参考本课程资料 {{ message.ragHits }} 段
                </div>
              </div>
              <div class="chat-footer opacity-50 flex gap-1 text-xs">
                <span>{{ formatTime(message.timestamp) }}</span>
                <button 
                  v-if="message.content" 
                  class="opacity-50 hover:opacity-100" 
                  @click="copyToClipboard(message.content)"
                  title="复制内容"
                >
                  <i class="fas fa-copy"></i>
                </button>
              </div>
            </div>
          </div>
          <div class="h-6"></div>
        </template>
      </div>

      <!-- 输入区域 -->
      <div class="input-container">
        <div class="flex flex-col gap-1">
          <div class="flex items-center gap-1 mb-1">
            <div class="flex items-center gap-1 text-xs text-base-content/50 flex-1">
              <i class="fas fa-robot text-secondary text-xs"></i>
              <span>AI 课程助手 · 本地 Agent</span>
              <!-- 课堂终端已连接标识 -->
              <span v-if="hasTerminalLogs" class="badge badge-success badge-xs ml-1">
                <i class="fas fa-circle text-[8px] mr-0.5"></i>终端已连接
              </span>
            </div>
            <!-- 一键提示按钮 -->
            <button
              v-if="hasTerminalLogs"
              class="btn btn-xs btn-warning gap-1"
              @click="sendHint"
              :disabled="isLoading"
              title="让 AI 助手读取课堂终端日志并给出提示"
            >
              <i class="fas fa-lightbulb text-xs"></i>
              一键提示
            </button>
          </div>
          <div class="join w-full">
            <textarea
              class="textarea textarea-bordered join-item flex-1 min-h-[40px] max-h-[80px] resize-none focus:outline-primary text-xs"
              placeholder="输入您的问题..."
              v-model="inputMessage"
              @keydown.enter.ctrl="handleSendMessage"
              ref="inputField"
            ></textarea>
          </div>
          <div class="flex justify-between items-center">
            <div class="text-xs text-base-content/60">
              Ctrl+Enter
            </div>
            <button
              class="btn btn-xs btn-primary"
              @click="handleSendMessage"
              :disabled="isLoading || !inputMessage.trim()"
            >
              <i class="fas fa-paper-plane mr-1"></i>
              发送
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount, nextTick, watch, computed } from 'vue'
import MarkdownRenderer from './MarkdownRenderer.vue'
import {
  currentLabContext,
  guidanceAlerts,
  markGuidanceAlertsRead,
  ttyLogLines,
  videoPosition,
  type GuidanceAlert
} from '../composables/useLabState'
import { reportLearningEvent } from '../api'
import { findAiModuleById } from '../data/aiModules'

// 本地 Agent SSE 事件类型（与后端 llm_client 输出一致）
interface AgentChunk {
  event: string
  conversation_id?: string
  answer?: string
  message_id?: string
  id?: string
  thought?: string
  observation?: string
  tool?: string
  tool_input?: string  // 工具调用入参（JSON 字符串）
  message?: string
  ragHits?: number     // meta 事件：本次回答参考的课程资料段落数
  courseId?: number | string
}

// 单次工具调用记录
interface ToolCall {
  id: string
  tool: string
  toolInput?: string   // 格式化后的入参摘要
  observation?: string // 工具返回结果
  status: 'calling' | 'done'
}

interface Message {
  role: 'user' | 'assistant'
  content: string
  timestamp: Date
  thinking?: string
  streamContent?: string
  isStreaming?: boolean
  showThinking?: boolean
  toolCalls?: ToolCall[]  // 该消息产生的工具调用列表
  ragHits?: number        // 本次回答参考了 N 段教师上传的课程资料
  // Phase 3: proactive guidance 主动提示字段
  isGuidance?: boolean
  signal_id?: string          // 关联 guidanceAlerts 中的 signal_id
  trigger_reason?: string     // repeated_error / stuck_loop / repeated_command
  guidance_status?: 'streaming' | 'done' | 'error'
}

const props = defineProps({
  visible: {
    type: Boolean,
    default: true
  },
  compact: {
    type: Boolean,
    default: false
  },
  initialPosition: {
    type: Object,
    default: () => ({ x: 20, y: 20 })
  },
  /** 当前运行中的靶机容器名（空字符串=无靶机）*/
  labContainer: {
    type: String,
    default: ''
  },
  /** 父组件传入：true 时自动发送一键提示消息 */
  autoHint: {
    type: Boolean,
    default: false
  },
  /** 来自 iframe postMessage 的自定义提示文本（非空时自动发送）*/
  iframeHintPrompt: {
    type: String,
    default: ''
  }
})

const emit = defineEmits(['close', 'toggle-visibility', 'hint-sent'])

/** 当前课堂终端累计的日志行数（有日志才显示「一键提示」） */
const hasTerminalLogs = computed(() => ttyLogLines.value.length > 0)

/** 把模拟终端最近的输出拼成文本，随对话发给后端，让 AI 有能力“读日志” */
const terminalLogText = computed(() =>
  ttyLogLines.value.slice(-80).map((line) => line.line).join('\n')
)

/**
 * 课程上下文：对话前让 AI 知道当前在学哪一讲、有什么题目。
 * 从 useLabState 的 moduleId 关联到本地 aiModules 数据（与页面展示同源）。
 */
const lessonContext = computed(() => {
  const ctx = currentLabContext.value
  // 只有 moduleId / experimentId 才对应 aiModules 里的实践模块；
  // courseId 是课程主键，不能拿去找模块，否则会把课程误认成第 N 个实践模块。
  const rawModuleId = ctx.moduleId ?? ctx.experimentId
  const moduleId = Number(rawModuleId)
  const lesson = Number.isFinite(moduleId) && moduleId > 0
    ? findAiModuleById(moduleId)
    : undefined

  const questions = lesson?.taskPoints.flatMap((task) =>
    task.questions.map((q) => ({
      id: q.id,
      type: q.type,
      content: q.content,
      score: q.score,
      options: q.options,
      analysis: q.analysis,
      reference: q.reference
    }))
  ) ?? []

  return {
    moduleId: ctx.moduleId ?? lesson?.id ?? null,
    moduleName: ctx.moduleName ?? lesson?.name ?? '',
    experimentId: ctx.experimentId ?? null,
    experimentTitle: ctx.experimentTitle ?? lesson?.name ?? '',
    courseId: ctx.courseId ?? lesson?.id ?? null,
    courseName: ctx.courseName ?? '',
    category: lesson?.category ?? '',
    currentTask: ctx.currentTask ?? lesson?.taskPoints[0]?.name ?? '',
    labSessionId: ctx.labSessionId ?? '',
    userId: ctx.userId ?? null,
    classId: ctx.classId ?? null,
    objectives: lesson?.objectives ?? [],
    questions
  }
})

const labContextText = computed(() => {
  const context = currentLabContext.value
  const entries = [
    ['模块ID', context.moduleId],
    ['模块名称', context.moduleName],
    ['实验ID', context.experimentId],
    ['实验标题', context.experimentTitle],
    ['当前任务', context.currentTask],
    ['会话ID', context.labSessionId],
    ['终端日志行数', ttyLogLines.value.length],
    ['用户ID', context.userId],
    ['班级ID', context.classId],
    ['课程ID', context.courseId]
  ]
  return entries
    .filter(([, value]) => value !== undefined && value !== null && String(value).trim() !== '')
    .map(([label, value]) => `${label}: ${value}`)
    .join('\n')
})

function normalizeOptionalNumber(value: unknown) {
  const numeric = Number(value)
  return Number.isFinite(numeric) && numeric > 0 ? numeric : null
}

function buildEventId(prefix: string) {
  return `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`
}

async function persistAiInteractionEvent(userQuestion: string, assistantReply: string, toolCalls: ToolCall[]) {
  const context = currentLabContext.value
  await reportLearningEvent({
    event_id: buildEventId('evt-ai'),
    request_id: buildEventId('req-ai'),
    event_type: 'AI_INTERACTION',
    event_time: new Date().toISOString(),
    user_id: normalizeOptionalNumber(context.userId),
    class_id: normalizeOptionalNumber(context.classId),
    course_id: normalizeOptionalNumber(context.courseId),
    module_id: normalizeOptionalNumber(context.moduleId),
    task_id: null,
    question_id: null,
    lab_session_id: context.labSessionId || null,
    container_name: null,
    target_url: null,
    prompt: userQuestion,
    assistant_reply: assistantReply,
    message_role: 'user',
    used_context_injection: Boolean(labContextText.value),
    context: labContextText.value
      ? {
          moduleId: context.moduleId ?? null,
          moduleName: context.moduleName ?? null,
          experimentId: context.experimentId ?? null,
          experimentTitle: context.experimentTitle ?? null,
          currentTask: context.currentTask ?? null,
          labSessionId: context.labSessionId ?? null,
          terminalLogLines: ttyLogLines.value.length,
          userId: context.userId ?? null,
          classId: context.classId ?? null,
          courseId: context.courseId ?? null,
        }
      : null,
    tool_calls: toolCalls.map((toolCall) => ({
      id: toolCall.id,
      tool: toolCall.tool,
      tool_input: toolCall.toolInput || '',
      observation: toolCall.observation || '',
      status: toolCall.status,
    })),
  })
}

// ── 一键提示 ─────────────────────────────────────────────────────
// 模拟终端的每一行输出都会写入 ttyLogLines；发消息时随请求体一并提交，
// 由后端拼进 query，AI 助手就能基于学生真实的操作轨迹给出提示。
const sendHint = () => {
  inputMessage.value = '请根据我最近的几次终端操作，给出我接下来需要怎么做的提示'
  handleSendMessage()
  emit('hint-sent')
}

// 监听父组件 autoHint 变化（父组件从弹窗触发）
watch(() => props.autoHint, (val) => {
  if (val) sendHint()
})

// 监听来自 iframe postMessage 的提示文本
watch(() => props.iframeHintPrompt, (prompt) => {
  if (prompt) {
    inputMessage.value = prompt
    handleSendMessage()
    emit('hint-sent')
  }
})

// 悬浮窗状态
const isMinimized = ref(false)
const isMaximized = ref(false)

const position = ref(props.initialPosition)
const isDragging = ref(false)
const dragOffset = ref({ x: 0, y: 0 })

// 聊天状态
const messages = ref<Message[]>([])
const inputMessage = ref('')
const isLoading = ref(false)
const chatContainer = ref<HTMLElement | null>(null)
const inputField = ref<HTMLTextAreaElement | null>(null)
// Agent 服务地址（指向本地 FastAPI）
const AGENT_BASE_URL = import.meta.env.VITE_AGENT_BASE_URL || 'http://localhost:8010'

// 会话 ID（保持多轮对话上下文）
const conversationId = ref<string>('')

// 工具名称 → 可读标签映射（若模型返回工具调用，这里做友好展示）
const TOOL_LABELS: Record<string, string> = {
  'get_container_logs':   '📋 读取终端日志',
  'get_terminal_logs':    '📋 读取终端日志',
  'read_lesson_context':  '📚 读取课程上下文',
  'search_knowledge':     '🔍 检索课程知识库',
}

// 格式化工具入参（JSON → 人类可读摘要）
const formatToolInput = (raw: string): string => {
  try {
    const obj = JSON.parse(raw)
    const parts: string[] = []
    if (obj.log_source)     parts.push(`来源: ${obj.log_source}`)
    if (obj.tail)           parts.push(`最近 ${obj.tail} 行`)
    if (obj.command)        parts.push(`命令: ${obj.command}`)
    if (obj.name)           parts.push(`名称: ${obj.name}`)
    return parts.length ? parts.join(' | ') : raw
  } catch {
    return raw
  }
}

// 格式化时间
const formatTime = (date: Date) => {
  return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}

// 复制到剪贴板
const copyToClipboard = (text: string) => {
  navigator.clipboard.writeText(text)
    .then(() => {
      console.log('复制成功')
    })
    .catch(err => {
      console.error('复制失败:', err)
    })
}

// 滚动到底部
const scrollToBottom = () => {
  if (chatContainer.value) {
    setTimeout(() => {
      if (chatContainer.value) {
        chatContainer.value.scrollTop = chatContainer.value.scrollHeight + 100
      }
    }, 100)
  }
}

// ── 调用本地 Agent（SSE 流式）──────────────────────────────
const callAgent = async (userQuestion: string, messageIndex: number) => {
  messages.value[messageIndex].isStreaming = true
  messages.value[messageIndex].streamContent = ''
  messages.value[messageIndex].showThinking = false
  messages.value[messageIndex].thinking = ''

  let completeResponse = ''
  let completeThinking = ''
  // 部分模型的 answer 里可能包含 <think>...</think> 思考过程标签，
  // 需要流式过滤，只把实际回答拼入 completeResponse。
  let inThinkBlock = false

  try {
    // 本地 Agent 模式：终端日志 + 课程上下文一起提交。
    // 后端把 lab_context（当前课程/任务/题目）写进 system prompt，
    // AI 在回答前就知道学生正在学哪一讲、有哪些题目。
    const response = await fetch(`${AGENT_BASE_URL}/api/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        query: userQuestion,
        conversation_id: conversationId.value,
        user: 'student',
        inputs: {},
        terminal_log: terminalLogText.value || null,
        log_source: 'simulated-terminal',
        log_tail: 80,
        lab_context: lessonContext.value,
        videoPosition: videoPosition.value
      })
    })

    if (!response.ok || !response.body) {
      throw new Error(`HTTP ${response.status}: ${await response.text()}`)
    }

    const reader = response.body.getReader()
    const decoder = new TextDecoder('utf-8')
    let buffer = ''

    while (true) {
      const { done, value } = await reader.read()
      if (done) break

      buffer += decoder.decode(value, { stream: true })
      const lines = buffer.split('\n')
      buffer = lines.pop() ?? ''                       // 保留不完整行

      for (const line of lines) {
        const trimmed = line.trim()
        if (!trimmed.startsWith('data:')) continue
        const raw = trimmed.slice(5).trim()
        if (!raw || raw === '[DONE]') continue

        try {
          const chunk = JSON.parse(raw) as AgentChunk

          // 保存 conversation_id 用于多轮对话
          if (chunk.conversation_id) {
            conversationId.value = chunk.conversation_id
          }

          // 课程资料检索命中（教师上传文档的 RAG）
          if (chunk.event === 'meta' && chunk.ragHits) {
            messages.value[messageIndex].ragHits = chunk.ragHits
          }

          // Agent 思考步骤（仅保留工具调用卡片，不显示纯思考文字）
          if (chunk.event === 'agent_thought') {
            // 工具调用 → 可视化卡片
            if (chunk.tool) {
              const tcId = chunk.id || `tc-${Date.now()}-${Math.random()}`
              const toolCalls = messages.value[messageIndex].toolCalls || []
              const existing = toolCalls.find((tc: ToolCall) => tc.id === tcId)

              if (!existing) {
                // 第一次收到此工具调用（calling 状态）
                toolCalls.push({
                  id: tcId,
                  tool: chunk.tool,
                  toolInput: chunk.tool_input ? formatToolInput(chunk.tool_input) : '',
                  observation: chunk.observation || '',
                  status: chunk.observation ? 'done' : 'calling'
                } as ToolCall)
              } else {
                // 第二次收到（含 observation，done 状态）
                if (chunk.observation) {
                  existing.observation = chunk.observation
                  existing.status = 'done'
                }
              }
              messages.value[messageIndex].toolCalls = toolCalls
              nextTick(() => scrollToBottom())
            }
          }

          // 流式回答文本片段（过滤 <think>...</think> 思考过程）
          if (chunk.event === 'agent_message' || chunk.event === 'message') {
            let delta = chunk.answer ?? ''
            if (delta) {
              // 流式过滤 <think> 标签：标签可能跨多个分片
              while (delta) {
                if (inThinkBlock) {
                  // 在 think 块内，寻找 </think> 结束标记
                  const endIdx = delta.indexOf('</think>')
                  if (endIdx >= 0) {
                    inThinkBlock = false
                    delta = delta.substring(endIdx + 8)
                  } else {
                    delta = ''  // 整个分片都在 think 块内，丢弃
                  }
                }
                if (!inThinkBlock && delta) {
                  const startIdx = delta.indexOf('<think>')
                  if (startIdx >= 0) {
                    const endIdx = delta.indexOf('</think>', startIdx)
                    if (endIdx >= 0) {
                      // 同一分片内闭合，去掉 think 块，继续处理剩余部分
                      delta = delta.substring(0, startIdx) + delta.substring(endIdx + 8)
                    } else {
                      // think 块开始但未闭合
                      inThinkBlock = true
                      delta = delta.substring(0, startIdx)
                    }
                  } else {
                    break  // 没有 think 标签，正常处理
                  }
                }
              }
              if (delta) {
                completeResponse += delta
                messages.value[messageIndex].streamContent = completeResponse
                nextTick(() => scrollToBottom())
              }
            }
          }

          // 消息结束
          if (chunk.event === 'message_end') {
            messages.value[messageIndex].content = completeResponse
            messages.value[messageIndex].isStreaming = false
          }

          // 错误事件
          if (chunk.event === 'error') {
            throw new Error(chunk.message || '未知错误')
          }
        } catch (_) {
          // JSON 解析失败时跳过该行
        }
      }
    }

    // 兜底：流结束但未收到 message_end
    if (messages.value[messageIndex].isStreaming) {
      messages.value[messageIndex].content = completeResponse || '（无回复）'
      messages.value[messageIndex].isStreaming = false
    }

  } catch (error: any) {
    messages.value[messageIndex].streamContent = ''
    messages.value[messageIndex].content = `连接 Agent 服务失败：${error.message || '未知错误'}`
    messages.value[messageIndex].isStreaming = false
  }

  const finalReply =
    messages.value[messageIndex].content ||
    messages.value[messageIndex].streamContent ||
    completeResponse

  try {
    await persistAiInteractionEvent(userQuestion, finalReply, messages.value[messageIndex].toolCalls || [])
  } catch (eventError) {
    console.warn('AI interaction learning event report failed:', eventError)
  }
}

// 发送消息
const handleSendMessage = () => {
  if (!inputMessage.value.trim() || isLoading.value) return

  // 如果窗口最小化，先还原
  if (isMinimized.value) {
    isMinimized.value = false
  }

  const newMessage: Message = {
    role: 'user',
    content: inputMessage.value,
    timestamp: new Date()
  }

  messages.value.push(newMessage)
  const userQuestion = inputMessage.value
  inputMessage.value = ''
  
  // 自动滚动到底部
  scrollToBottom()
  
  // 添加加载状态的消息
  isLoading.value = true
  const responseIndex = messages.value.length
  messages.value.push({
    role: 'assistant',
    content: '',
    timestamp: new Date(),
    toolCalls: []
  })
  
  // 确保滚动到底部
  scrollToBottom()
  
  // 调用本地 Agent
  callAgent(userQuestion, responseIndex)
    .finally(() => {
      isLoading.value = false
      // 回答完成后再次滚动到底部
      scrollToBottom()
    })
}

// 悬浮窗控制函数
const toggleMinimize = () => {
  isMinimized.value = !isMinimized.value
  if (isMinimized.value) {
    isMaximized.value = false
  }
}

const toggleMaximize = () => {
  isMaximized.value = !isMaximized.value
}

const closeChat = () => {
  emit('close')
}

// 拖动功能
const startDragging = (event: MouseEvent) => {
  // 如果点击的是控制按钮，不启动拖动
  if ((event.target as HTMLElement).closest('button')) {
    return
  }
  
  isDragging.value = true
  const chatElement = (event.currentTarget as HTMLElement).parentElement as HTMLElement
  const rect = chatElement.getBoundingClientRect()
  
  dragOffset.value = {
    x: event.clientX - rect.left,
    y: event.clientY - rect.top
  }
  
  document.addEventListener('mousemove', onDrag)
  document.addEventListener('mouseup', stopDragging)
}

const onDrag = (event: MouseEvent) => {
  if (!isDragging.value) return
  
  const viewportWidth = window.innerWidth
  const viewportHeight = window.innerHeight
  const chatElement = document.querySelector('.floating-chat') as HTMLElement
  const width = chatElement.offsetWidth
  const height = chatElement.offsetHeight
  
  // 计算新位置，确保不超出视口
  const newX = Math.max(0, Math.min(viewportWidth - width, event.clientX - dragOffset.value.x))
  const newY = Math.max(0, Math.min(viewportHeight - height, event.clientY - dragOffset.value.y))
  
  // 转换为right和bottom定位
  position.value = {
    x: viewportWidth - newX - width,
    y: viewportHeight - newY - height
  }
}

const stopDragging = () => {
  isDragging.value = false
  document.removeEventListener('mousemove', onDrag)
  document.removeEventListener('mouseup', stopDragging)
}

// 监听消息变化
watch(messages, () => {
  nextTick(() => {
    scrollToBottom()
  })
}, { deep: true })

// 从localStorage加载聊天记录
const loadMessagesFromStorage = () => {
  try {
    const savedMessages = localStorage.getItem('chatMessages')
    if (savedMessages) {
      // 需要将JSON字符串中的日期字符串转换回Date对象
      const parsedMessages = JSON.parse(savedMessages, (key, value) => {
        if (key === 'timestamp' && value) {
          return new Date(value)
        }
        return value
      })
      messages.value = parsedMessages
    }
  } catch (error) {
    console.error('加载聊天记录失败:', error)
  }
}

// ── Phase 3: Proactive Guidance 同步到消息列表 ───────────────
/**
 * 把 guidanceAlerts 同步到 messages 数组：
 * - 新 alert → push assistant message（isGuidance=true）
 * - 已存在 alert（按 signal_id 匹配）→ 更新 content/streamContent/isStreaming/guidance_status
 * 找不到匹配 alert 的 guidance 消息保留（用户可手动滚动查看历史）。
 */
function syncGuidanceAlertsToMessages() {
  for (const alert of guidanceAlerts.value) {
    const existingIdx = messages.value.findIndex(
      (m) => m.isGuidance && m.signal_id === alert.signal_id
    )
    if (existingIdx === -1) {
      // 新 alert → push 新消息
      messages.value.push({
        role: 'assistant',
        content: alert.content,
        streamContent: alert.content,
        timestamp: new Date(alert.started_at),
        isStreaming: alert.status === 'streaming',
        isGuidance: true,
        signal_id: alert.signal_id,
        trigger_reason: alert.trigger_reason,
        guidance_status: alert.status,
      })
    } else {
      // 已存在 → 原地更新（保留 timestamp）
      const msg = messages.value[existingIdx]
      msg.content = alert.content
      msg.streamContent = alert.content
      msg.isStreaming = alert.status === 'streaming'
      msg.guidance_status = alert.status
      if (alert.status === 'error' && alert.error_message) {
        msg.content = `⚠️ ${alert.error_message}`
      }
    }
  }
  nextTick(() => scrollToBottom())
}

// 组件挂载
onMounted(() => {
  // 加载聊天记录
  loadMessagesFromStorage()

  // Phase 3: 同步已累积的 guidance 主动提示到消息列表
  syncGuidanceAlertsToMessages()
  // 打开聊天即标记已读（FloatingChatButton 徽标归零）
  markGuidanceAlertsRead()

  // 聚焦输入框
  if (!isMinimized.value) {
    inputField.value?.focus()
  }

  // 监听窗口大小变化，确保悬浮窗不超出视口
  window.addEventListener('resize', () => {
    const viewportWidth = window.innerWidth
    const viewportHeight = window.innerHeight
    const chatElement = document.querySelector('.floating-chat') as HTMLElement

    if (chatElement) {
      const width = chatElement.offsetWidth
      const height = chatElement.offsetHeight

      position.value = {
        x: Math.min(position.value.x, viewportWidth - width),
        y: Math.min(position.value.y, viewportHeight - height)
      }
    }
  })
})

// Phase 3: guidanceAlerts 变化时实时同步到消息列表（聊天打开期间）
watch(guidanceAlerts, () => {
  syncGuidanceAlertsToMessages()
}, { deep: true })
</script>

<style scoped>
.floating-chat {
  position: fixed;
  display: flex;
  flex-direction: column;
  width: 350px;
  height: 450px;
  background-color: var(--fallback-b1,oklch(var(--b1)/var(--tw-bg-opacity, 1)));
  border-radius: 0.5rem;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
  transition: all 0.3s ease;
  z-index: 1000;
  overflow: hidden;
  border: 1px solid var(--b3);
}

.floating-chat.minimized {
  width: 200px;
  height: 40px;
}

.floating-chat.maximized {
  width: 450px;
  height: 650px;
}

.drag-handle {
  height: 40px;
  width: 100%;
  cursor: move;
  display: flex;
  align-items: center;
  background-color: var(--b2);
  border-bottom: 1px solid var(--b3);
  user-select: none;
}

.chat-container {
  display: flex;
  flex-direction: column;
  height: calc(100% - 40px);
}

.messages-container {
  flex-grow: 1;
  overflow-y: auto;
  padding: 0.5rem;
  background-color: var(--b1, #131414);
}

.input-container {
  padding: 0.5rem;
  border-top: 1px solid var(--b3);
  background-color: var(--b2);
}

:deep(.chat-bubble) {
  max-width: 85%;
  word-break: break-word;
  box-shadow: 0 1px 2px rgba(0,0,0,0.05);
}

.assistant-bubble {
  background-color: var(--color-base-100);
  color: var(--color-base-content);
  border: 1px solid var(--color-base-300);
}

.assistant-bubble :deep(.markdown-body),
.assistant-bubble :deep(.markdown-body p),
.assistant-bubble :deep(.markdown-body li),
.assistant-bubble :deep(.markdown-body h1),
.assistant-bubble :deep(.markdown-body h2),
.assistant-bubble :deep(.markdown-body h3),
.assistant-bubble :deep(.markdown-body blockquote) {
  color: var(--color-base-content);
}

.assistant-bubble :deep(.markdown-body code),
.assistant-bubble :deep(.markdown-body pre) {
  background-color: var(--color-base-200);
  color: var(--color-base-content);
}

:deep(.chat-bubble a) {
  color: var(--p);
  text-decoration: underline;
}

:deep(.chat-bubble pre) {
  background-color: hsl(var(--n) / 0.1);
  padding: 0.5rem;
  border-radius: 0.3rem;
  overflow-x: auto;
  margin: 0.5rem 0;
  font-size: 0.7rem;
}

:deep(.chat-bubble code) {
  background-color: hsl(var(--n) / 0.1);
  padding: 0.1rem 0.2rem;
  border-radius: 0.2rem;
  font-size: 0.7rem;
}

.empty-state {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  height: 100%;
}

.rag-cite {
  display: inline-flex;
  align-items: center;
  gap: 0.3rem;
  margin: 0 0.5rem 0.4rem;
  padding: 0.12rem 0.5rem;
  border-radius: 0.6rem;
  font-size: 0.68rem;
  color: hsl(var(--su));
  background-color: hsl(var(--su) / 0.12);
}
</style> 

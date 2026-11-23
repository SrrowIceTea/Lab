<template>
  <div>
    <!-- 悬浮按钮 -->
    <button
      v-if="!chatVisible"
      @click="openChat"
      class="fixed bottom-6 right-6 btn btn-circle btn-primary shadow-lg hover:shadow-xl transition-all duration-300 z-30 w-14 h-14"
      title="AI 学习助手（可读取当前课堂终端日志）"
    >
      <i class="fas fa-comment-dots text-xl"></i>
      <span
        v-if="guidanceUnreadCount > 0"
        class="absolute -top-1 -left-1 min-w-[20px] h-[20px] px-1 bg-error text-error-content text-[10px] font-bold rounded-full flex items-center justify-center border-2 border-base-100 z-10 shadow-md"
      >
        {{ guidanceUnreadCount > 9 ? '9+' : guidanceUnreadCount }}
      </span>
    </button>

    <!-- 聊天窗口：始终传入当前实践模块的上下文；终端日志由 FloatingChat 自行读取 -->
    <FloatingChat
      v-if="chatVisible"
      :initial-position="chatPosition"
      :compact="compact"
      :auto-hint="pendingHint"
      @close="chatVisible = false"
      @hint-sent="pendingHint = false"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, watch, onUnmounted } from 'vue'
import FloatingChat from './FloatingChat.vue'
import {
  currentLabContext,
  guidanceUnreadCount,
  addGuidanceAlert,
  updateGuidanceAlert,
  appendGuidanceChunk
} from '../composables/useLabState'
import { subscribeGuidanceStream } from '../api'

const props = defineProps({
  compact: { type: Boolean, default: true },
  defaultPosition: { type: Object, default: () => ({ x: 20, y: 20 }) }
})

const chatVisible = ref(false)
const chatPosition = ref(props.defaultPosition)
const pendingHint = ref(false)

function openChat(withHint = false) {
  if (withHint) pendingHint.value = true
  chatVisible.value = true
}

// ── 主动提示 SSE 订阅 ─────────────────────────────────────────
// 订阅放在始终挂载的按钮组件里，聊天窗口关闭时也能接收提示。
let unsubscribeGuidance: (() => void) | null = null

function setupGuidanceSubscription(labSessionId: string) {
  if (unsubscribeGuidance) {
    unsubscribeGuidance()
    unsubscribeGuidance = null
  }
  if (!labSessionId) return

  unsubscribeGuidance = subscribeGuidanceStream(labSessionId, {
    onReady: () => {},
    onGuidanceStart: (evt) => {
      addGuidanceAlert({
        signal_id: evt.signal_id,
        trigger_reason: evt.trigger_reason,
        conversation_id: evt.conversation_id,
        error_context: evt.error_context,
        content: '',
        status: 'streaming',
        started_at: evt.ts
      })
    },
    onChunk: (evt) => appendGuidanceChunk(evt.signal_id, evt.content),
    onError: (evt) => updateGuidanceAlert(evt.signal_id, {
      status: 'error',
      error_message: evt.message,
      ended_at: evt.ts
    }),
    onGuidanceEnd: (evt) => updateGuidanceAlert(evt.signal_id, {
      status: 'done',
      message_id: evt.message_id,
      conversation_id: evt.conversation_id,
      ended_at: evt.ts
    }),
    onParseError: (raw, err) => console.warn('[guidance] SSE parse error:', raw, err)
  })
}

watch(
  () => currentLabContext.value.labSessionId,
  (newId, oldId) => {
    if (newId && newId !== oldId) setupGuidanceSubscription(newId)
  },
  { immediate: true }
)

onUnmounted(() => {
  if (unsubscribeGuidance) unsubscribeGuidance()
})
</script>

<script setup lang="ts">
/**
 * 课堂实践详情页（人工智能微课）
 *
 * 改造说明：本页由原网络安全「实验详情 / 靶机做题页」重写而成。
 * - 移除了 Docker 启动、靶机 iframe、VNC 远程桌面、Flag 提交等全部靶场逻辑；
 * - 数据源改为本地 aiModules.ts（10 讲对应的 AI 课堂实践）；
 * - 保留并强化了「模拟终端 + AI 助手读日志」链路：每条命令与回显都会写入
 *   useLabState 的 ttyLogLines，右下角 AI 助手会把这些日志随对话发给后端。
 * 后续替换点：若教师端需要真实作答记录，可将 submitAnswers() 换成后端作答接口。
 */
import { computed, nextTick, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import MarkdownRenderer from '../../../components/MarkdownRenderer.vue'
import { findAiModuleById, getTerminalOutput } from '../../../data/aiModules'
import type { AiModule, AiQuestion } from '../../../data/aiModules'
import {
  addTtyLogLine,
  clearTtyLogLines,
  setLabContext,
  setLabSessionId
} from '../../../composables/useLabState'

const route = useRoute()
const router = useRouter()

const moduleData = ref<AiModule | null>(null)
const loading = ref(true)
const commandInput = ref('')
const terminalOutput = ref<Array<{ kind: 'system' | 'command' | 'stdout' | 'stderr'; text: string }>>([])
const terminalBox = ref<HTMLElement | null>(null)

const answers = ref<Record<number, string | number[]>>({})
const submitted = ref<Record<number, boolean>>({})

const totalScore = computed(() =>
  moduleData.value?.taskPoints.reduce((sum, task) => sum + task.score, 0) ?? 0
)

const earnedScore = computed(() => {
  const m = moduleData.value
  if (!m) return 0
  let total = 0
  for (const task of m.taskPoints) {
    for (const q of task.questions) {
      if (!submitted.value[q.id] || !isCorrect(q)) continue
      total += q.score
    }
  }
  return total
})

const answeredCount = computed(() => Object.values(submitted.value).filter(Boolean).length)

function isCorrect(question: AiQuestion): boolean {
  const chosen = answers.value[question.id]
  if (question.type === 'short-answer') {
    return typeof chosen === 'string' && chosen.trim().length >= 10
  }
  if (!Array.isArray(chosen) || !question.answer) return false
  const a = [...chosen].sort().join(',')
  const b = [...question.answer].sort().join(',')
  return a === b
}

function chooseOption(question: AiQuestion, index: number) {
  if (submitted.value[question.id]) return
  if (question.type === 'multiple-choice') {
    const current = Array.isArray(answers.value[question.id]) ? (answers.value[question.id] as number[]) : []
    answers.value[question.id] = current.includes(index)
      ? current.filter((i) => i !== index)
      : [...current, index]
  } else {
    answers.value[question.id] = [index]
  }
}

// ─────────────────────────────────────────
//  AI 陪练：评分 / 提示 / 变式题
// ─────────────────────────────────────────
const AGENT_BASE_URL = import.meta.env.VITE_AGENT_BASE_URL || 'http://localhost:8010'
interface AiGrade {
  score: number
  hitPoints: string[]
  missedPoints: string[]
  comment: string
  suggestion: string
  graded: boolean
}
const aiGrades = ref<Record<number, AiGrade | null>>({})
const aiHints = ref<Record<number, string[]>>({})
const hintSteps = ref<Record<number, number>>({})
const coachLoading = ref<Record<number, boolean>>({})
const variants = ref<Record<number, AiQuestion | null>>({})
const openCoach = ref<Record<number, boolean>>({})

async function aiGrade(question: AiQuestion) {
  const answer = answers.value[question.id]
  if (typeof answer !== 'string' || !answer.trim()) return
  coachLoading.value[question.id] = true
  try {
    const res = await fetch(`${AGENT_BASE_URL}/api/coach/grade`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        question: question.content,
        answer,
        reference: question.reference || '',
        analysis: question.analysis || ''
      })
    })
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    aiGrades.value[question.id] = await res.json()
    openCoach.value[question.id] = true
  } catch (err: any) {
    aiGrades.value[question.id] = {
      score: 0, hitPoints: [], missedPoints: [],
      comment: 'AI 评分暂不可用', suggestion: err?.message || '', graded: false
    }
    openCoach.value[question.id] = true
  } finally {
    coachLoading.value[question.id] = false
  }
}

async function aiHint(question: AiQuestion) {
  coachLoading.value[question.id] = true
  try {
    const step = (hintSteps.value[question.id] || 0) + 1
    const res = await fetch(`${AGENT_BASE_URL}/api/coach/hint`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        question: question.content,
        answer: typeof answers.value[question.id] === 'string' ? answers.value[question.id] : '',
        reference: question.reference || '',
        step
      })
    })
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    const data = await res.json()
    if (!aiHints.value[question.id]) aiHints.value[question.id] = []
    aiHints.value[question.id].push(data.hint)
    hintSteps.value[question.id] = step
    openCoach.value[question.id] = true
  } catch (err: any) {
    if (!aiHints.value[question.id]) aiHints.value[question.id] = []
    aiHints.value[question.id].push(`提示获取失败：${err?.message || err}`)
    openCoach.value[question.id] = true
  } finally {
    coachLoading.value[question.id] = false
  }
}

async function aiVariant(question: AiQuestion) {
  coachLoading.value[question.id] = true
  try {
    const res = await fetch(`${AGENT_BASE_URL}/api/coach/variant`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        question: { ...question } as any,
        seed: Date.now() % 10000
      })
    })
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    variants.value[question.id] = await res.json()
    openCoach.value[question.id] = true
  } catch (err: any) {
    variants.value[question.id] = {
      id: 90000 + question.id, type: 'short-answer',
      content: `变式题生成失败：${err?.message || err}`, score: question.score
    }
    openCoach.value[question.id] = true
  } finally {
    coachLoading.value[question.id] = false
  }
}

function submitQuestion(question: AiQuestion) {
  const chosen = answers.value[question.id]
  if (question.type === 'short-answer') {
    if (typeof chosen !== 'string' || chosen.trim().length < 10) {
      window.alert('请至少写 10 个字，说明你的思考。')
      return
    }
  } else if (!Array.isArray(chosen) || chosen.length === 0) {
    window.alert('请先选择一个答案。')
    return
  }
  submitted.value[question.id] = true
  // 简答题提交后自动触发 AI 评分
  if (question.type === 'short-answer') void aiGrade(question)
}

function scrollTerminal() {
  void nextTick(() => {
    if (terminalBox.value) terminalBox.value.scrollTop = terminalBox.value.scrollHeight
  })
}

async function runCommand(raw?: string) {
  const command = (raw ?? commandInput.value).trim()
  if (!command || !moduleData.value) return
  commandInput.value = ''
  terminalOutput.value.push({ kind: 'command', text: command })
  addTtyLogLine({ ts: new Date().toISOString(), stream: 'stdout', line: `$ ${command}` })

  const lines = getTerminalOutput(moduleData.value, command)
  if (lines.length === 1 && lines[0] === '__CLEAR__') {
    terminalOutput.value = []
    clearTtyLogLines()
    return
  }
  for (const line of lines) {
    terminalOutput.value.push({ kind: 'stdout', text: line })
    addTtyLogLine({ ts: new Date().toISOString(), stream: 'stdout', line })
  }
  scrollTerminal()
}

onMounted(() => {
  const id = Number(route.params.id)
  const found = findAiModuleById(Number.isNaN(id) ? 1 : id)
  if (!found) {
    router.push('/user/modules')
    return
  }
  moduleData.value = found
  const now = new Date().toISOString()
  for (const line of found.terminal.welcome) {
    terminalOutput.value.push({ kind: 'system', text: line })
    addTtyLogLine({ ts: now, stream: 'stdout', line })
  }
  setLabSessionId(`ai-practice-${found.id}-${Date.now()}`)
  setLabContext({
    moduleId: found.id,
    moduleName: found.name,
    experimentId: found.id,
    experimentTitle: found.name,
    courseId: found.id,
    currentTask: found.taskPoints[0]?.name,
    userId: null
  })
  loading.value = false
})
</script>

<template>
  <div class="container-fluid px-4 py-6 overflow-x-hidden">
    <div v-if="loading" class="flex justify-center py-20">
      <span class="loading loading-spinner loading-lg text-primary"></span>
    </div>

    <template v-else-if="moduleData">
      <!-- 课程简介 -->
      <div class="card bg-base-100 shadow-xl mb-6">
        <div class="card-body">
          <div class="flex flex-wrap items-start justify-between gap-4">
            <div class="flex-1 min-w-[260px]">
              <div class="flex flex-wrap items-center gap-2 mb-2">
                <span class="badge badge-primary">{{ moduleData.category }}</span>
                <span class="badge badge-outline">第 {{ moduleData.id }} 讲 · 课堂实践</span>
                <span class="badge badge-ghost">建议用时 {{ moduleData.estimatedTime }}</span>
              </div>
              <h1 class="text-2xl md:text-3xl font-bold">{{ moduleData.name }}</h1>
              <p class="text-base-content/70 mt-3 leading-relaxed">{{ moduleData.introduction }}</p>
            </div>
            <div class="text-right">
              <div class="text-sm text-base-content/60">实践得分</div>
              <div class="text-3xl font-bold text-primary">{{ earnedScore }}<span class="text-base"> / {{ totalScore }}</span></div>
              <div class="text-sm text-base-content/60 mt-1">已作答 {{ answeredCount }} 题</div>
            </div>
          </div>

          <div class="mt-4">
            <div class="text-sm font-semibold mb-2">学习目标</div>
            <ul class="list-disc list-inside text-base-content/80 space-y-1">
              <li v-for="(objective, i) in moduleData.objectives" :key="i">{{ objective }}</li>
            </ul>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
        <!-- 任务与题目 -->
        <div class="xl:col-span-2 space-y-6">
          <div
            v-for="(task, taskIndex) in moduleData.taskPoints"
            :key="task.id"
            class="card bg-base-100 shadow-lg"
          >
            <div class="card-body">
              <div class="flex items-center justify-between flex-wrap gap-2">
                <h2 class="card-title">
                  <span class="badge badge-neutral">{{ taskIndex + 1 }}</span>
                  {{ task.name }}
                </h2>
                <span class="badge badge-accent badge-outline">{{ task.score }} 分</span>
              </div>
              <p class="text-base-content/70">{{ task.description }}</p>

              <div class="my-4 p-4 rounded-lg bg-base-200/60">
                <MarkdownRenderer :content="task.document" />
              </div>

              <div class="space-y-6">
                <div v-for="question in task.questions" :key="question.id" class="border-t border-base-200 pt-4">
                  <div class="flex items-start justify-between gap-3">
                    <div class="font-medium">
                      <span class="badge badge-ghost mr-2">{{ question.id }}</span>{{ question.content }}
                    </div>
                    <span class="badge badge-outline whitespace-nowrap">{{ question.score }} 分</span>
                  </div>

                  <!-- 选择题 -->
                  <div v-if="question.type !== 'short-answer' && question.options" class="mt-3 space-y-2">
                    <label
                      v-for="(option, index) in question.options"
                      :key="index"
                      class="flex items-center gap-3 p-3 rounded-lg border border-base-300 cursor-pointer hover:bg-base-200/60 transition-colors"
                      :class="{
                        'bg-primary/10 border-primary': (() => {
                          const v = answers[question.id]
                          return Array.isArray(v) && v.includes(index)
                        })(),
                        'bg-success/10 border-success': submitted[question.id] && !!question.answer?.includes(index),
                        'bg-error/10 border-error': submitted[question.id] && Array.isArray(answers[question.id]) && (answers[question.id] as number[]).includes(index) && !question.answer?.includes(index)
                      }"
                    >
                      <input
                        :type="question.type === 'multiple-choice' ? 'checkbox' : 'radio'"
                        class="checkbox checkbox-sm"
                        :name="`q-${question.id}`"
                        :checked="Array.isArray(answers[question.id]) && (answers[question.id] as number[]).includes(index)"
                        :disabled="!!submitted[question.id]"
                        @change="chooseOption(question, index)"
                      />
                      <span>{{ option }}</span>
                    </label>
                  </div>

                  <!-- 简答题 -->
                  <div v-else class="mt-3">
                    <textarea
                      v-model="(answers[question.id] as string)"
                      class="textarea textarea-bordered w-full min-h-[100px]"
                      placeholder="写下你的思考（至少 10 个字）..."
                      :disabled="!!submitted[question.id]"
                    ></textarea>
                  </div>

                  <div class="mt-3 flex items-center gap-3 flex-wrap">
                    <button
                      v-if="!submitted[question.id]"
                      class="btn btn-primary btn-sm"
                      @click="submitQuestion(question)"
                    >提交本题</button>
                    <span v-else class="badge" :class="isCorrect(question) ? 'badge-success' : 'badge-error'">
                      {{ isCorrect(question) ? '回答正确' : '继续加油' }}
                    </span>
                    <span v-if="submitted[question.id] && question.analysis" class="text-sm text-base-content/70">
                      {{ question.analysis }}
                    </span>
                  </div>

                  <!-- AI 陪练按钮 -->
                  <div class="mt-3 flex gap-2 flex-wrap">
                    <button
                      class="btn btn-xs btn-outline"
                      :disabled="coachLoading[question.id]"
                      @click="aiHint(question)"
                    >
                      <i class="fas fa-lightbulb mr-1"></i>给点提示
                    </button>
                    <button
                      v-if="submitted[question.id]"
                      class="btn btn-xs btn-outline"
                      :disabled="coachLoading[question.id]"
                      @click="aiGrade(question)"
                    >
                      <i class="fas fa-check-double mr-1"></i>AI 评分
                    </button>
                    <button
                      class="btn btn-xs btn-outline"
                      :disabled="coachLoading[question.id]"
                      @click="aiVariant(question)"
                    >
                      <i class="fas fa-sync mr-1"></i>再练一题
                    </button>
                    <button
                      v-if="aiGrades[question.id] || aiHints[question.id]?.length || variants[question.id]"
                      class="btn btn-xs btn-ghost"
                      @click="openCoach[question.id] = !openCoach[question.id]"
                    >
                      {{ openCoach[question.id] ? '收起' : '展开 AI 反馈' }}
                    </button>
                  </div>

                  <!-- AI 陪练反馈面板 -->
                  <div v-if="openCoach[question.id]" class="mt-3 space-y-3">
                    <!-- 评分 -->
                    <div v-if="aiGrades[question.id]" class="p-3 rounded-lg bg-primary/5 border border-primary/20">
                      <div class="flex items-center gap-2 mb-2">
                        <i class="fas fa-robot text-primary"></i>
                        <span class="font-medium text-sm">AI 评分</span>
                        <span class="badge badge-primary badge-sm">{{ aiGrades[question.id]!.score }} 分</span>
                      </div>
                      <p v-if="aiGrades[question.id]!.comment" class="text-sm mb-1">{{ aiGrades[question.id]!.comment }}</p>
                      <div v-if="aiGrades[question.id]!.hitPoints.length" class="text-sm text-success">
                        <div class="font-medium">已命中：</div>
                        <ul class="list-disc list-inside">
                          <li v-for="(p, i) in aiGrades[question.id]!.hitPoints" :key="i">{{ p }}</li>
                        </ul>
                      </div>
                      <div v-if="aiGrades[question.id]!.missedPoints.length" class="text-sm text-warning mt-1">
                        <div class="font-medium">还可补充：</div>
                        <ul class="list-disc list-inside">
                          <li v-for="(p, i) in aiGrades[question.id]!.missedPoints" :key="i">{{ p }}</li>
                        </ul>
                      </div>
                      <p v-if="aiGrades[question.id]!.suggestion" class="text-sm text-base-content/70 mt-2">
                        <i class="fas fa-arrow-right mr-1"></i>{{ aiGrades[question.id]!.suggestion }}
                      </p>
                    </div>

                    <!-- 提示 -->
                    <div v-if="aiHints[question.id]?.length" class="p-3 rounded-lg bg-warning/10 border border-warning/30">
                      <div class="flex items-center gap-2 mb-2">
                        <i class="fas fa-lightbulb text-warning"></i>
                        <span class="font-medium text-sm">分步提示</span>
                      </div>
                      <p v-for="(h, i) in aiHints[question.id]" :key="i" class="text-sm mb-1">
                        <span class="badge badge-ghost badge-xs mr-1">{{ i + 1 }}</span>{{ h }}
                      </p>
                    </div>

                    <!-- 变式题 -->
                    <div v-if="variants[question.id]" class="p-3 rounded-lg bg-secondary/10 border border-secondary/30">
                      <div class="flex items-center gap-2 mb-2">
                        <i class="fas fa-sync text-secondary"></i>
                        <span class="font-medium text-sm">变式练习</span>
                      </div>
                      <p class="text-sm mb-2">{{ variants[question.id]!.content }}</p>
                      <div v-if="variants[question.id]!.options" class="space-y-1 mb-2">
                        <label
                          v-for="(opt, i) in variants[question.id]!.options"
                          :key="i"
                          class="flex items-center gap-2 p-2 rounded border border-base-300 text-sm"
                        >{{ opt }}</label>
                      </div>
                      <details v-if="variants[question.id]!.analysis || variants[question.id]!.reference" class="text-sm">
                        <summary class="cursor-pointer text-base-content/60">查看解析</summary>
                        <p class="mt-1">{{ variants[question.id]!.analysis || variants[question.id]!.reference }}</p>
                      </details>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- 教学模拟终端 -->
        <div class="xl:col-span-1">
          <div class="card bg-base-100 shadow-lg sticky top-4">
            <div class="card-body">
              <h2 class="card-title text-lg">
                <i class="fas fa-terminal"></i>
                教学模拟终端
              </h2>
              <p class="text-sm text-base-content/60">
                输入命令观察结果。命令与回显会自动同步给右下角 AI 助手，
                可以直接问它“我刚才做的这一步说明了什么？”。
              </p>

              <div
                ref="terminalBox"
                class="mt-3 h-[320px] overflow-y-auto rounded-lg bg-neutral text-neutral-content p-3 font-mono text-xs leading-relaxed"
              >
                <div
                  v-for="(line, i) in terminalOutput"
                  :key="i"
                  :class="{
                    'text-info': line.kind === 'system',
                    'text-warning': line.kind === 'command',
                    'text-error': line.kind === 'stderr'
                  }"
                >{{ line.kind === 'command' ? `$ ${line.text}` : line.text }}</div>
              </div>

              <form class="mt-3 flex gap-2" @submit.prevent="runCommand()">
                <input
                  v-model="commandInput"
                  class="input input-bordered input-sm flex-1 font-mono"
                  :placeholder="moduleData.terminal.prompt"
                />
                <button class="btn btn-primary btn-sm" type="submit">运行</button>
              </form>

              <div class="mt-4">
                <div class="text-sm font-semibold mb-2">推荐尝试</div>
                <div class="flex flex-wrap gap-2">
                  <button
                    v-for="cmd in moduleData.terminal.suggested"
                    :key="cmd"
                    class="btn btn-outline btn-xs"
                    @click="runCommand(cmd)"
                  >{{ cmd }}</button>
                </div>
              </div>

              <div class="alert alert-info mt-4 text-sm">
                <span>本终端为本地教学模拟，不连接 Docker、靶机或任何远程容器。</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="mt-6 flex justify-end">
        <button class="btn btn-ghost" @click="router.push('/user/modules')">返回实践列表</button>
      </div>
    </template>

    <div v-else class="text-center py-20">
      <p class="text-lg">未找到该实践模块</p>
      <button class="btn btn-primary mt-4" @click="router.push('/user/modules')">返回实践列表</button>
    </div>
  </div>
</template>

<style scoped>
.container-fluid {
  width: 100%;
  max-width: 100%;
  margin: 0 auto;
}
</style>

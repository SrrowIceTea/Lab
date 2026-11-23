<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import type { User } from '../../../types/user'
import {
  diagnoseTraining,
  generateTrainingQuestionSet,
  generateTrainingQuestions,
  getProfileDashboard,
  getProfileLatest,
  getStudentCapabilityGrowth,
  getTrainingSessionSummary,
  getTrainingQuestions,
  getUserInfo,
  getUserTrainingSessions,
  image as resolveImage,
  uploadImageFile,
  type ProfileRecommendationItem,
  submitGeneratedQuestionAnswer,
  submitTrainingAnswer,
  updateUserInfoByToken,
  type GeneratedQuestionAnswerSubmitResponse,
  type GeneratedTrainingQuestion,
  type CapabilityGrowthResponseDto,
  type ProfileDashboardResponse,
  type ProfileLatestResponse,
  type TrainingDiagnoseResponse,
  type TrainingQuestionSetItem,
  type TrainingSessionSummaryResponse,
  type TrainingSingleQuestion,
  type TrainingSessionData,
  type WeakKnowledgePoint
} from '../../../api'
import { showToast, useCookie } from '../../../common'
import CapabilityGrowthPanel from '../../../components/CapabilityGrowthPanel.vue'
import SolveHistoryPanel from './SolveHistoryPanel.vue'
import TeacherAssignments from './TeacherAssignments.vue'
import { trainingGenerationErrorMessage, trainingWaitMessage } from './trainingReadiness'

type SolveRecord = ProfileDashboardResponse['solveRecords'][number]
type LoginStorageUser = Partial<User> & {
  studentNumber?: string
  studentNo?: string
  account?: string
  username?: string
  phone?: string
  major?: string
  data?: unknown
  loginData?: unknown
}

type AnalysisDimensionCard = {
  icon: string
  label: string
  desc: string
  borderClass: string
  iconClass: string
}

type ProfileRecommendationCard = {
  id: string
  title: string
  dimension: string
  dimensionName: string
  score: number
  scoreText: string
  resourceType: string
  resourceTypeLabel: string
  difficulty: number | null
  difficultyText: string
  priorityLabel: string
  priorityClass: string
  reason: string
  action: string
  actionText: string
  actionDisabled: boolean
  actionHint: string
  courseId: number | null
  moduleId: number | null
  labId: number | null
  knowledgeTags: string[]
  tags: string[]
}

type RecommendationQuestionState = {
  generatedQuestionId?: string
  question?: TrainingSingleQuestion | null
  answerVisible?: boolean
  teachingAnalysisVisible?: boolean
  studentAnswer?: string
  submittingAnswer?: boolean
  feedback?: GeneratedQuestionAnswerSubmitResponse | null
  loading: boolean
  trainingSessionId: string
  questions: RecommendationPracticeQuestion[]
  currentIndex: number
  answers: Record<string, string>
  attempts: Record<string, GeneratedQuestionAnswerSubmitResponse>
  submittedQuestionIds: string[]
  completed: boolean
  summaryLoading: boolean
  summary: TrainingSessionSummaryResponse | null
  error: string
  submitError: string
  doneNotice: string
}

type RecommendationPracticeQuestion = TrainingQuestionSetItem & {
  submitted: boolean
  submitting: boolean
  score: number | null
  level: string
  briefFeedback: string
  expanded: boolean
}

type TrainingRecommendationCard = {
  id: string
  title: string
  difficulty: string
  difficultyClass: string
  type: string
  tags: string[]
  reason: string
  moduleId?: number | null
  taskId?: number | null
  source: WeakKnowledgePoint
}

type TrainingQuestionViewModel = GeneratedTrainingQuestion & {
  currentAnswer: string
  submitting: boolean
  submitted: boolean
  isCorrect: boolean | null
  score: number | null
  submitError: string
  startedAt: number
  costTime: number | null
  explanationVisible: boolean
}

type ProfileOverviewCard = {
  title: string
  value: string
  desc: string
  badge: string
  badgeClass: string
  icon: string
  iconClass: string
}

const cookie = useCookie()
const router = useRouter()
const STORAGE_USER_KEYS = ['userInfo', 'currentUser', 'user', 'loginUser', 'loginData', 'tokenUser', 'studentInfo', 'auth_student_number']
const EMPTY_PROFILE_MESSAGE = '暂无画像数据，完成课堂实践、使用 AI 助手后将生成画像。'
const PROFILE_LOAD_ERROR_MESSAGE = '画像数据加载失败，请稍后重试。'
const EMPTY_RECOMMENDATIONS_MESSAGE = '暂无推荐任务'
const RECOMMENDATION_PRACTICE_COUNT = 7
// 与后端画像维度保持一致（ai-agent-service: DIMENSION_VIEW / capability_growth_service: DIMENSIONS）
const EMPTY_SKILLS = [
  { name: '知识掌握', score: 0, color: 'text-primary' },
  { name: '排障能力', score: 0, color: 'text-secondary' },
  { name: '自主探索', score: 0, color: 'text-accent' },
  { name: 'AI协同', score: 0, color: 'text-info' },
  { name: '学习投入', score: 0, color: 'text-success' }
]
const user = ref<User>({
  userId: 0,
  userStudentNumber: '',
  userName: '',
  userEmail: '',
  userTel: '',
  userAcademy: '',
  userClass: '',
  userGender: 1,
  userImage: '',
  classId: 0
})

const editedUser = ref<User>({ ...user.value })
const profileMajor = ref('')

const isLoadingUserData = ref(false)
const isEditing = ref(false)
const showProfileModal = ref(false)

// 头像上传相关状态
const avatarFile = ref<File | null>(null)
const avatarPreviewUrl = ref('')
const isUploadingAvatar = ref(false)
const avatarError = ref('')
const isLoading = ref(false)
const isLoaded = ref(false)

const userStats = ref({
  completedCourses: 0,
  totalScore: 0,
  ranking: 0,
  activeStreak: 0
})

const learningProfile = ref({
  skills: EMPTY_SKILLS.map((skill) => ({ ...skill })),
  tags: [] as ProfileDashboardResponse['learningProfile']['tags'],
  recentFocus: '',
  comprehensiveScore: 0,
  evaluation: '暂无学习记录'
})

const solveRecords = ref<SolveRecord[]>([])

const latestProfile = ref<ProfileLatestResponse | null>(null)
const capabilityGrowth = ref<CapabilityGrowthResponseDto | null>(null)
const capabilityGrowthLoading = ref(false)
const capabilityGrowthError = ref('')
const trainingDiagnoseResult = ref<TrainingDiagnoseResponse | null>(null)
const userTrainingSessions = ref<TrainingSessionData[]>([])
const activeTrainingSessionId = ref('')
const trainingQuestions = ref<TrainingQuestionViewModel[]>([])
const showTrainingView = ref(false)

const isLoadingDashboard = ref(false)
const dashboardLoaded = ref(true)
const dashboardError = ref('')
const pageNotice = ref('')

const diagnosing = ref(false)
const diagnoseError = ref('')
const generatingQuestions = ref(false)
const generateError = ref('')
const generatingRecommendationId = ref('')
const generationElapsedSeconds = ref(0)
let generationElapsedTimer: ReturnType<typeof setInterval> | null = null
const recommendationQuestionStates = ref<Record<string, RecommendationQuestionState>>({})
const refreshingProfileAfterSubmit = ref(false)
const profileRefreshError = ref('')
const displayProfile = computed(() => ({
  userName: user.value.userName || '未填写',
  studentNo: user.value.userStudentNumber || '未填写',
  className: user.value.userClass || '未填写',
  college: user.value.userAcademy || '未填写',
  major: profileMajor.value || '未填写',
  email: user.value.userEmail || '未填写',
  phone: user.value.userTel || '未填写'
}))

function asRecord(value: unknown): Record<string, unknown> | null {
  return value !== null && typeof value === 'object' ? (value as Record<string, unknown>) : null
}

function parseStorageValue(raw: string) {
  const text = raw.trim()
  if (!text) return null
  if ((text.startsWith('{') && text.endsWith('}')) || (text.startsWith('[') && text.endsWith(']'))) {
    try {
      return JSON.parse(text)
    } catch {
      return raw
    }
  }
  return raw
}

// 兜底修复后端未及时处理或数据库中残留的 mojibake 乱码
// 对应 Python 端 _repair_double_encoded_utf8 的逻辑
// 安全策略：只在确认是乱码时修复，绝不把正确中文"修复"成乱码
function repairMojibakeText(input: string): string {
  if (!input || typeof input !== 'string') return input
  if (input.length > 0 && /^[\x00-\x7F]+$/.test(input)) return input
  // 纯中文（CJK + 标点 + 空格 + 数字 + %），非乱码，直接跳过
  if (/^[\u4E00-\u9FFF\s\u3000-\u303F\uFF00-\uFFEF，。、；：？！（）—《》【】「」·%.\d]+$/.test(input)) {
    return input
  }

  // 特征统计
  let latin1HighCount = 0
  let asciiAlphaCount = 0
  for (const ch of input) {
    const code = ch.charCodeAt(0)
    if (code >= 0x80 && code <= 0xFF) latin1HighCount++
    if (code <= 0x7F && ((code >= 65 && code <= 90) || (code >= 97 && code <= 122))) asciiAlphaCount++
  }
  const hasCJK = /[\u4E00-\u9FFF]/.test(input)

  // 策略 1：Latin-1 高位字节修复（安全：正确中文均在 U+4E00+，不受影响）
  if (latin1HighCount > 0) {
    for (const enc of ['latin1', 'cp1252']) {
      try {
        const bytes = new Uint8Array(input.length)
        let valid = true
        for (let i = 0; i < input.length; i++) {
          const code = input.charCodeAt(i)
          if (code > 0xFF) { valid = false; break }
          bytes[i] = code
        }
        if (!valid) continue
        const decoder = new TextDecoder('utf-8')
        const repaired = decoder.decode(bytes)
        if (repaired !== input && /[\u4E00-\u9FFF]/.test(repaired)) {
          return repaired
        }
      } catch { /* ignore */ }
    }
  }

  // 策略 2：GBK 乱码修复 —— 已禁用
  // 原因：含有 CJK + ASCII 字母的文本既可能是乱码（"涓嶤SRF鍩虹"）也可能是正确文本
  // （如 "已匹配真实模块「人工智能入门微课」"），无法可靠区分。
  // 此策略会将正确 UTF-8 编码后按 GBK 解码，导致正确文本被破坏成乱码。
  // 后端 _repair_double_encoded_utf8 已对数据库读取的数据做编码修复，前端无需重复。
  const hasGarbledMix = false

  return input
}

// 深度修复对象/数组内的字符串字段
function repairMojibakeDeep<T>(value: T): T {
  if (typeof value === 'string') {
    return repairMojibakeText(value) as unknown as T
  }
  if (Array.isArray(value)) {
    return value.map((v) => repairMojibakeDeep(v)) as unknown as T
  }
  if (value && typeof value === 'object') {
    const out: Record<string, unknown> = {}
    for (const [k, v] of Object.entries(value as Record<string, unknown>)) {
      out[k] = repairMojibakeDeep(v)
    }
    return out as unknown as T
  }
  return value
}

function candidateRecords(value: unknown): Record<string, unknown>[] {
  const queue = [value]
  const records: Record<string, unknown>[] = []

  while (queue.length) {
    const current = queue.shift()
    const record = asRecord(current)
    if (!record) continue
    records.push(record)
    if (record.data) queue.push(record.data)
    if (record.loginData) queue.push(record.loginData)
  }

  return records
}

function readFirstString(record: Record<string, unknown>, keys: string[]) {
  for (const key of keys) {
    const value = record[key]
    if (value === null || value === undefined) continue
    const normalized = String(value).trim()
    if (normalized) return normalized
  }
  return ''
}

function getCurrentLoginUser(): LoginStorageUser | null {
  if (typeof window === 'undefined') return null

  const merged: LoginStorageUser = {}
  const storages = [window.localStorage, window.sessionStorage]

  const assignIfEmpty = (key: keyof LoginStorageUser, value: unknown) => {
    const normalized = value === null || value === undefined ? '' : String(value).trim()
    if (!normalized) return
    if (!merged[key]) {
      merged[key] = normalized as never
    }
  }

  for (const storage of storages) {
    for (const key of STORAGE_USER_KEYS) {
      const raw = storage.getItem(key)
      if (!raw) continue

      if (key === 'auth_student_number') {
        assignIfEmpty('userStudentNumber', raw)
        assignIfEmpty('studentNumber', raw)
        assignIfEmpty('studentNo', raw)
        assignIfEmpty('account', raw)
        continue
      }

      const parsed = parseStorageValue(raw)
      for (const record of candidateRecords(parsed)) {
        assignIfEmpty('userName', readFirstString(record, ['userName', 'username', 'accountName', 'name']))
        assignIfEmpty('username', readFirstString(record, ['username', 'userName', 'accountName', 'name']))
        assignIfEmpty('userStudentNumber', readFirstString(record, ['userStudentNumber', 'studentNumber', 'studentNo', 'account']))
        assignIfEmpty('studentNumber', readFirstString(record, ['studentNumber', 'userStudentNumber', 'studentNo', 'account']))
        assignIfEmpty('studentNo', readFirstString(record, ['studentNo', 'studentNumber', 'userStudentNumber', 'account']))
        assignIfEmpty('account', readFirstString(record, ['account', 'studentNumber', 'userStudentNumber']))
        assignIfEmpty('userEmail', readFirstString(record, ['userEmail', 'email']))
        assignIfEmpty('userTel', readFirstString(record, ['userTel', 'phone', 'mobile']))
        assignIfEmpty('phone', readFirstString(record, ['phone', 'mobile', 'userTel']))
        assignIfEmpty('userAcademy', readFirstString(record, ['userAcademy', 'college', 'academy']))
        assignIfEmpty('userClass', readFirstString(record, ['userClass', 'className', 'class']))
        assignIfEmpty('major', readFirstString(record, ['major', 'specialty']))
      }
    }
  }

  return Object.keys(merged).length ? merged : null
}

function createEmptyTrainingDiagnose(userId: number, classId = 0, courseId = 0): TrainingDiagnoseResponse {
  return {
    profile_snapshot_id: null,
    user_id: userId,
    class_id: classId || null,
    course_id: courseId || null,
    dimension_scores: {
      knowledge_mastery_score: 0,
      troubleshooting_score: 0,
      autonomy_score: 0,
      ai_collaboration_score: 0,
      engagement_score: 0,
      overall_score: 0
    },
    weak_dimensions: [],
    tags: [],
    recent_focus: '',
    weak_knowledge_points: [],
    generation_constraints: {
      difficulty: 'medium',
      question_types: ['single_choice', 'fill_blank', 'short_answer'],
      question_count: 5
    },
    recent_evidence: {
      recent_errors: [],
      recent_failed_tasks: [],
      recent_ai_topics: []
    }
  }
}

function applyEmptyProfileBundle(loginUser?: LoginStorageUser | null) {
  const userName = loginUser?.userName || loginUser?.username || ''
  const studentNumber = loginUser?.userStudentNumber || loginUser?.studentNumber || loginUser?.studentNo || loginUser?.account || ''
  const email = loginUser?.userEmail || ''
  const phone = loginUser?.userTel || loginUser?.phone || ''
  const academy = loginUser?.userAcademy || ''
  const className = loginUser?.userClass || ''

  user.value = {
    userId: user.value.userId || 0,
    userStudentNumber: studentNumber,
    userName,
    userEmail: email,
    userTel: phone,
    userAcademy: academy,
    userClass: className,
    userGender: typeof user.value.userGender === 'number' ? user.value.userGender : 1,
    userImage: loginUser?.userImage || '',
    classId: user.value.classId || 0
  }
  editedUser.value = { ...user.value }
  profileMajor.value = loginUser?.major || ''
  userStats.value = {
    completedCourses: 0,
    totalScore: 0,
    ranking: 0,
    activeStreak: 0
  }
  learningProfile.value = {
    skills: EMPTY_SKILLS.map((skill) => ({ ...skill })),
    tags: [],
    recentFocus: '',
    comprehensiveScore: 0,
    evaluation: '暂无学习记录'
  }
  solveRecords.value = []
  latestProfile.value = null
  capabilityGrowth.value = null
  capabilityGrowthError.value = ''
  trainingDiagnoseResult.value = createEmptyTrainingDiagnose(user.value.userId || 0, user.value.classId || 0, 0)
  userTrainingSessions.value = []
}

function hasMeaningfulDashboardData(profileDashboard: ProfileDashboardResponse | null) {
  if (!profileDashboard) return false

  const hasStats = Object.values(profileDashboard.userStats || {}).some((value) => Number(value || 0) > 0)
  const hasSkills = (profileDashboard.learningProfile?.skills || []).some((skill) => Number(skill.score || 0) > 0)
  const hasTags = Boolean(profileDashboard.learningProfile?.tags?.length)
  const hasRecords = Boolean(profileDashboard.solveRecords?.length)

  return hasStats || hasSkills || hasTags || hasRecords
}

function hasMeaningfulLatestProfile(profile: ProfileLatestResponse | null) {
  return Boolean(profile?.snapshot_id || profile?.overall_score || profile?.knowledge_mastery_score)
}

const displayUserImage = computed(() => {
  const img = user.value.userImage?.trim()
  return img ? resolveImage(img) : ''
})

const currentUserId = computed(() => user.value.userId || 0)

const currentClassId = computed(() => {
  return user.value.classId ?? latestProfile.value?.class_id ?? trainingDiagnoseResult.value?.class_id ?? userTrainingSessions.value[0]?.class_id ?? 1
})

const currentCourseId = computed(() => {
  return latestProfile.value?.course_id ?? trainingDiagnoseResult.value?.course_id ?? userTrainingSessions.value[0]?.course_id ?? 1
})

const currentProfileSnapshotId = computed(() => {
  return trainingDiagnoseResult.value?.profile_snapshot_id ?? latestProfile.value?.snapshot_id ?? null
})

const latestProfileComputedAt = computed(() => {
  const raw = latestProfile.value?.computed_at || latestProfile.value?.created_at || ''
  return raw ? raw.replace('T', ' ').slice(0, 16) : '未同步'
})

const classRankText = computed(() => {
  const ranking = Number(userStats.value.ranking || 0)
  return ranking > 0 ? `#${ranking}` : '--'
})

const strongestSkill = computed(() => {
  const [first] = [...learningProfile.value.skills].sort((a, b) => b.score - a.score)
  return first || { name: '学习投入', score: 0, color: 'text-success' }
})

const weakestSkill = computed(() => {
  const [first] = [...learningProfile.value.skills].sort((a, b) => a.score - b.score)
  return first || { name: 'AI协同', score: 0, color: 'text-info' }
})

// AI 协同维度得分：对应后端 DIMENSION_VIEW 的 ai_collaboration_score
const aiCollaborationScore = computed(() => {
  const skill = learningProfile.value.skills.find((item) => item.name.replace(/\s/g, '') === 'AI协同')
  return Number(skill?.score || 0)
})

// 连续学习天数：后端 userStats.activeStreak 已计算，此前前端未展示
const activeStreakDays = computed(() => Number(userStats.value.activeStreak || 0))

const profileStageSummary = computed(() => {
  const score = Number(learningProfile.value.comprehensiveScore || 0)
  if (score <= 0) return { label: '待生成', desc: EMPTY_PROFILE_MESSAGE, badgeClass: 'badge-ghost' }
  if (score >= 85) return { label: '稳定拔高期', desc: '已具备较强的自主学习与人机协作能力，可尝试跨学科综合项目与同伴共创。', badgeClass: 'badge-success' }
  if (score >= 70) return { label: '能力成型期', desc: '基础能力稳定，正在通过专项训练补齐薄弱项，成长轨迹清晰可追踪。', badgeClass: 'badge-primary' }
  return { label: '重点提升期', desc: '画像已明确主要短板，系统正在围绕弱项持续生成针对性训练。', badgeClass: 'badge-warning' }
})

const displayTags = computed(() => {
  if (learningProfile.value.tags.length) {
    return learningProfile.value.tags
  }
  return [{ text: '暂无学习徽章', type: 'badge-ghost' }]
})

const profileOverviewCards = computed<ProfileOverviewCard[]>(() => {
  const hasScore = Number(learningProfile.value.comprehensiveScore || 0) > 0

  return [
    {
      title: '学习状态',
      value: profileStageSummary.value.label,
      desc: profileStageSummary.value.desc,
      badge: `综合分 ${learningProfile.value.comprehensiveScore}`,
      badgeClass: profileStageSummary.value.badgeClass,
      icon: 'fa-signal',
      iconClass: 'text-primary'
    },
    {
      title: '最近更新',
      value: latestProfileComputedAt.value,
      desc: '根据课程练习、实验操作与 AI 对话记录综合更新。',
      badge: currentProfileSnapshotId.value ? '已更新' : '待更新',
      badgeClass: currentProfileSnapshotId.value ? 'badge-success' : 'badge-warning',
      icon: 'fa-camera-retro',
      iconClass: 'text-secondary'
    },
    {
      title: '当前优势',
      value: hasScore ? `${strongestSkill.value.name} ${strongestSkill.value.score}` : '暂无',
      desc: hasScore
        ? `${strongestSkill.value.name}表现相对稳定，可把它迁移到更综合的 AI 学习任务中。`
        : '当前账号暂无可展示的优势项目。',
      badge: hasScore ? '持续稳定' : '待生成',
      badgeClass: hasScore ? 'badge-info' : 'badge-ghost',
      icon: 'fa-medal',
      iconClass: strongestSkill.value.color
    },
    {
      title: '下一步提升',
      value: hasScore ? `${weakestSkill.value.name} ${weakestSkill.value.score}` : '暂无',
      desc: hasScore
        ? `后续训练会优先围绕${weakestSkill.value.name}生成针对性题目，帮助你补齐这一维度。`
        : '当前账号暂无学习反馈，完成练习后将生成提升建议。',
      badge: hasScore ? '继续提升' : '待生成',
      badgeClass: hasScore ? 'badge-error' : 'badge-ghost',
      icon: 'fa-bullseye',
      iconClass: weakestSkill.value.color
    },
  ]
})

const recentTrainingCards = computed(() => {
  if (userTrainingSessions.value.length) {
    return userTrainingSessions.value.slice(0, 3).map((session, index) => ({
      id: session.training_session_id,
      title: index === 0 ? '最近一次专项训练' : `历史训练 ${index + 1}`,
      time: session.created_at ? session.created_at.replace('T', ' ').slice(0, 16) : '近期生成',
      desc: `共生成 ${session.question_count || 0} 题，已完成 ${session.attempt_count || 0} 次作答，训练结果会直接回流到画像评估。`
    }))
  }

  return [
    {
      id: 'prep-1',
      title: currentProfileSnapshotId.value ? '首轮画像训练待开始' : '暂无学习记录',
      time: currentProfileSnapshotId.value ? '随时可发起' : '--',
      desc: currentProfileSnapshotId.value
        ? '系统已根据当前画像准备好训练路径，点击“开始练习”即可生成第一轮个性化题目。'
        : EMPTY_PROFILE_MESSAGE
    }
  ]
})

const recentTrainingSummary = computed(() => {
  if (!userTrainingSessions.value.length) {
    return currentProfileSnapshotId.value
      ? '还没有个性化训练记录，系统会根据最新画像直接生成第一轮针对性训练。'
      : EMPTY_PROFILE_MESSAGE
  }
  const latest = userTrainingSessions.value[0]
  const createdAt = latest.created_at ? new Date(latest.created_at).toLocaleString() : '刚刚'
  return `最近一次训练生成于 ${createdAt}，累计训练 ${userTrainingSessions.value.length} 次。`
})

function getProfileSummaryValue(key: string) {
  const summary = latestProfile.value?.profile_summary_json
  if (!summary || typeof summary !== 'object') return undefined
  return (summary as Record<string, unknown>)[key]
}

function recommendationTypeLabel(type: ProfileRecommendationItem['type']) {
  switch (type) {
    case 'COURSE':
      return '课程'
    case 'MODULE':
      return '模块'
    case 'LAB':
      return '实验'
    case 'QUESTION':
      return '题目'
    default:
      return '通用建议'
  }
}

function recommendationActionHint(item: ProfileRecommendationItem) {
  if (item.moduleId || item.courseId) {
    return ''
  }
  return '暂无可跳转资源'
}

const profileRecommendations = computed<ProfileRecommendationCard[]>(() => {
  const rawRecommendations = getProfileSummaryValue('recommendations')
  if (!Array.isArray(rawRecommendations)) return []

  return rawRecommendations
    .filter((item): item is ProfileRecommendationItem => Boolean(item && typeof item === 'object'))
    .map((item) => {
      const score = Number(item.score || 0)
      const priorityLabel = item.priority === 'high' ? '高优先级' : '建议跟进'
      const difficulty = typeof item.difficulty === 'number' ? item.difficulty : null
      return {
        id: item.id,
        title: item.title,
        dimension: item.dimension,
        dimensionName: item.dimension_name || item.dimension,
        score,
        scoreText: Number.isFinite(score) ? score.toFixed(2) : '--',
        resourceType: item.type,
        resourceTypeLabel: recommendationTypeLabel(item.type),
        difficulty,
        difficultyText: difficulty ? `难度 ${difficulty}` : '难度未知',
        priorityLabel,
        priorityClass: item.priority === 'high' ? 'badge-error' : 'badge-warning',
        reason: item.reason,
        action: item.action || item.actionText,
        actionText: item.actionText || '开始训练',
        actionDisabled: !(item.moduleId || item.courseId),
        actionHint: recommendationActionHint(item),
        courseId: item.courseId,
        moduleId: item.moduleId,
        labId: item.labId,
        knowledgeTags: Array.isArray(item.knowledgeTags) ? item.knowledgeTags.filter((tag): tag is string => Boolean(tag)) : [],
        tags: Array.isArray(item.tags) ? item.tags.filter((tag): tag is string => Boolean(tag)) : []
      }
    })
})

const profileAnalysisDimensions = computed<AnalysisDimensionCard[]>(() => {
  const tones = [
    { borderClass: 'border-primary', iconClass: 'text-primary' },
    { borderClass: 'border-error', iconClass: 'text-error' },
    { borderClass: 'border-info', iconClass: 'text-info' },
    { borderClass: 'border-secondary', iconClass: 'text-secondary' }
  ]

  return profileRecommendations.value.map((item, index) => {
    const tone = tones[index % tones.length]
    return {
      icon: getDimensionIcon(item.dimensionName),
      label: item.dimensionName,
      desc: item.reason,
      borderClass: tone.borderClass,
      iconClass: tone.iconClass
    }
  })
})

const aiRecommendedTasks = computed(() => {
  const diagnose = trainingDiagnoseResult.value
  const tones = [
    { borderClass: 'border-primary', iconClass: 'text-primary' },
    { borderClass: 'border-error', iconClass: 'text-error' },
    { borderClass: 'border-info', iconClass: 'text-info' },
    { borderClass: 'border-secondary', iconClass: 'text-secondary' }
  ]

  const analysisDimensions: AnalysisDimensionCard[] = (diagnose?.weak_dimensions || []).map((dimension, index) => {
    const tone = tones[index % tones.length]
    return {
      icon: getDimensionIcon(dimension),
      label: dimension,
      desc: getDimensionDescription(dimension, index),
      borderClass: tone.borderClass,
      iconClass: tone.iconClass
    }
  })

  const difficulty = diagnose?.generation_constraints?.difficulty || 'medium'
  const generatedQuestions: TrainingRecommendationCard[] = (diagnose?.weak_knowledge_points || []).map((point) => ({
    id: `${point.knowledge_point_id ?? 'approx'}-${point.module_id ?? 'm'}-${point.task_id ?? 't'}-${point.name}`,
    title: point.name,
    difficulty: difficultyLabel(difficulty),
    difficultyClass: difficultyBadgeClass(difficulty),
    type: point.evidence_level === 'approximate' ? '近似诊断' : '精准诊断',
    tags: [
      point.category || '知识点',
      point.evidence_level === 'approximate' ? 'module/task 近似推断' : '画像证据',
      point.difficulty_level || '训练推荐'
    ].filter(Boolean),
    reason: point.reason,
    moduleId: point.module_id,
    taskId: point.task_id,
    source: point
  }))

  return {
    analysisDimensions,
    generatedQuestions
  }
})

function getDimensionIcon(dimension: string) {
  const iconMap: Record<string, string> = {
    知识掌握: 'fa-brain',
    知识掌握度: 'fa-brain',
    排障能力: 'fa-bug',
    自主探索: 'fa-compass',
    自主探索能力: 'fa-compass',
    AI协同: 'fa-robot',
    'AI 协作能力': 'fa-robot',
    学习投入: 'fa-fire',
    学习投入度: 'fa-fire'
  }
  return iconMap[dimension] || 'fa-chart-line'
}

function openRecommendationResource(item: ProfileRecommendationCard) {
  if (item.moduleId) {
    // 携带 from 参数，让目标页面的"返回"按钮能精确回到个人画像，
    // 避免 router.go(-1) 因历史栈混乱而跳到错误页面
    router.push(`/user/module/${item.moduleId}?from=/user/profile`)
    return
  }
  if (item.courseId) {
    router.push(`/user/course/${item.courseId}`)
    return
  }
}

function getRecommendationQuestionState(item: ProfileRecommendationCard) {
  return recommendationQuestionStates.value[item.id]
}

function canGenerateRecommendationQuestion(item: ProfileRecommendationCard) {
  return Boolean(item.moduleId || item.knowledgeTags.length)
}

function isGeneratingRecommendationQuestion(item: ProfileRecommendationCard) {
  return generatingRecommendationId.value === item.id
}

function createEmptyRecommendationPracticeState(patch: Partial<RecommendationQuestionState> = {}): RecommendationQuestionState {
  return {
    generatedQuestionId: '',
    question: null,
    answerVisible: false,
    teachingAnalysisVisible: false,
    studentAnswer: '',
    submittingAnswer: false,
    feedback: null,
    loading: false,
    trainingSessionId: '',
    questions: [],
    currentIndex: 0,
    answers: {},
    attempts: {},
    submittedQuestionIds: [],
    completed: false,
    summaryLoading: false,
    summary: null,
    error: '',
    submitError: '',
    doneNotice: '',
    ...patch
  }
}

function updateRecommendationQuestionState(item: ProfileRecommendationCard, patch: Partial<RecommendationQuestionState>) {
  const current = recommendationQuestionStates.value[item.id] || createEmptyRecommendationPracticeState()
  recommendationQuestionStates.value = {
    ...recommendationQuestionStates.value,
    [item.id]: {
      ...current,
      ...patch
    }
  }
}

function recommendationPracticeButtonLabel(item: ProfileRecommendationCard) {
  const state = getRecommendationQuestionState(item)
  if (isGeneratingRecommendationQuestion(item) || state?.loading) return `准备中 ${generationElapsedSeconds.value}s`
  if (state?.completed) return '查看训练报告'
  if (state?.trainingSessionId) return '继续训练'
  return '开始训练'
}

function currentRecommendationQuestion(state: RecommendationQuestionState | undefined) {
  if (!state?.questions.length) return null
  return state.questions[state.currentIndex] || state.questions[0]
}

function isLastRecommendationQuestion(state: RecommendationQuestionState | undefined) {
  if (!state?.questions.length) return false
  return state.currentIndex >= state.questions.length - 1
}

function currentRecommendationAnswer(state: RecommendationQuestionState | undefined) {
  const question = currentRecommendationQuestion(state)
  return question ? state?.answers[question.generatedQuestionId] || '' : ''
}

function updateRecommendationStudentAnswer(item: ProfileRecommendationCard, value: string) {
  const state = getRecommendationQuestionState(item)
  const question = currentRecommendationQuestion(state)
  if (!state || !question || question.submitted) return
  updateRecommendationQuestionState(item, {
    answers: {
      ...state.answers,
      [question.generatedQuestionId]: value
    },
    submitError: ''
  })
}

function goToNextRecommendationQuestion(item: ProfileRecommendationCard) {
  const state = getRecommendationQuestionState(item)
  if (!state) return
  const nextIndex = Math.min(state.currentIndex + 1, Math.max(state.questions.length - 1, 0))
  updateRecommendationQuestionState(item, {
    currentIndex: nextIndex,
    submitError: ''
  })
}

function toggleSummaryQuestion(item: ProfileRecommendationCard, generatedQuestionId: string) {
  const state = getRecommendationQuestionState(item)
  if (!state) return
  updateRecommendationQuestionState(item, {
    questions: state.questions.map((question) =>
      question.generatedQuestionId === generatedQuestionId
        ? { ...question, expanded: !question.expanded }
        : question
    )
  })
}

function backendErrorCode(error: unknown) {
  const response = asRecord(asRecord(error)?.response)
  const data = asRecord(response?.data)
  const detail = asRecord(data?.detail)
  const code = detail?.code
  return typeof code === 'string' ? code : ''
}

function isRequestTimeout(error: unknown) {
  const record = asRecord(error)
  const code = record?.code
  const message = record?.message
  return code === 'ECONNABORTED' || (typeof message === 'string' && message.toLowerCase().includes('timeout'))
}

function stopGenerationElapsedTimer() {
  if (generationElapsedTimer !== null) {
    clearInterval(generationElapsedTimer)
    generationElapsedTimer = null
  }
}

function startGenerationElapsedTimer() {
  stopGenerationElapsedTimer()
  generationElapsedSeconds.value = 0
  generationElapsedTimer = setInterval(() => {
    generationElapsedSeconds.value += 1
  }, 1000)
}

function toggleRecommendationAnswer(item: ProfileRecommendationCard) {
  const current = getRecommendationQuestionState(item)
  if (!current) return
  updateRecommendationQuestionState(item, {
    answerVisible: !current.answerVisible
  })
}

function toggleRecommendationTeachingAnalysis(item: ProfileRecommendationCard) {
  const current = getRecommendationQuestionState(item)
  if (!current) return
  updateRecommendationQuestionState(item, {
    teachingAnalysisVisible: !current.teachingAnalysisVisible
  })
}

function hasRecommendationTeachingAnalysis(question: TrainingSingleQuestion | null | undefined) {
  if (!question) return false
  return Boolean(
    question.teachingObjective ||
    question.expectedSkill ||
    question.difficultyReason ||
    question.commonMistakes?.length ||
    question.gradingRubric?.length ||
    typeof question.qualityScore === 'number' ||
    question.qualitySummary ||
    question.qualityFlags?.length
  )
}

function trainingQuestionErrorMessage(error: unknown) {
  return trainingGenerationErrorMessage(backendErrorCode(error), isRequestTimeout(error))
}

async function generateQuestionForRecommendation(item: ProfileRecommendationCard) {
  if (generatingRecommendationId.value) return

  const userId = currentUserId.value
  if (!userId) {
    showToast('请先登录')
    return
  }

  if (!canGenerateRecommendationQuestion(item)) {
    const message = '当前推荐缺少足够知识库上下文，暂不能生成训练题。'
    updateRecommendationQuestionState(item, createEmptyRecommendationPracticeState({ error: message }))
    showToast(message)
    return
  }

  generatingRecommendationId.value = item.id
  startGenerationElapsedTimer()
  updateRecommendationQuestionState(item, createEmptyRecommendationPracticeState({ loading: true }))

  try {
    const response = await generateTrainingQuestionSet({
      userId,
      dimension: item.dimension,
      recommendationId: item.id,
      moduleId: item.moduleId,
      courseId: item.courseId,
      knowledgeTags: item.knowledgeTags,
      difficulty: item.difficulty || 2,
      questionType: 'SHORT_ANSWER',
      count: RECOMMENDATION_PRACTICE_COUNT,
      source: 'student_profile_snapshot'
    })

    updateRecommendationQuestionState(item, {
      loading: false,
      trainingSessionId: response.trainingSessionId,
      questions: response.questions.map((question) => ({
        ...question,
        submitted: false,
        submitting: false,
        score: null,
        level: '',
        briefFeedback: '',
        expanded: false
      })),
      currentIndex: 0,
      answers: {},
      attempts: {},
      submittedQuestionIds: [],
      completed: false,
      summaryLoading: false,
      summary: null,
      error: '',
      submitError: '',
      doneNotice: ''
    })
    showToast('训练题已准备好')
  } catch (error) {
    const message = trainingQuestionErrorMessage(error)
    updateRecommendationQuestionState(item, createEmptyRecommendationPracticeState({ error: message }))
    showToast(message)
  } finally {
    stopGenerationElapsedTimer()
    if (generatingRecommendationId.value === item.id) {
      generatingRecommendationId.value = ''
    }
  }
}

function generatedAnswerErrorMessage(error: unknown) {
  switch (backendErrorCode(error)) {
    case 'EMPTY_ANSWER':
      return '请输入你的答案。'
    case 'ANSWER_TOO_SHORT':
      return '答案太短，请至少写出一个完整判断或理由。'
    case 'GENERATED_QUESTION_NOT_FOUND':
      return '训练题不存在，请重新生成。'
    case 'UNSUPPORTED_QUESTION_TYPE':
      return '当前题型暂不支持自动评分。'
    default:
      return '答案提交失败，请稍后重试。'
  }
}

function feedbackLevelLabel(level?: string) {
  switch (level) {
    case 'EXCELLENT':
      return '优秀'
    case 'GOOD':
      return '良好'
    case 'PARTIAL':
      return '部分掌握'
    case 'NEEDS_REVIEW':
      return '需要复习'
    default:
      return level || '待评估'
  }
}

function feedbackLevelClass(level?: string) {
  switch (level) {
    case 'EXCELLENT':
      return 'badge-success'
    case 'GOOD':
      return 'badge-info'
    case 'PARTIAL':
      return 'badge-warning'
    default:
      return 'badge-error'
  }
}

async function submitRecommendationAnswer(item: ProfileRecommendationCard) {
  const state = getRecommendationQuestionState(item)
  const question = currentRecommendationQuestion(state)
  const userId = currentUserId.value
  if (!state || !question || question.submitting || question.submitted) return
  if (!userId) {
    showToast('请先登录')
    return
  }
  const answer = (state.answers[question.generatedQuestionId] || '').trim()
  if (!answer) {
    updateRecommendationQuestionState(item, { submitError: '请输入你的答案。' })
    return
  }

  updateRecommendationQuestionState(item, {
    questions: state.questions.map((itemQuestion) =>
      itemQuestion.generatedQuestionId === question.generatedQuestionId
        ? { ...itemQuestion, submitting: true }
        : itemQuestion
    ),
    submitError: ''
  })

  try {
    const response = await submitGeneratedQuestionAnswer(question.generatedQuestionId, {
      userId,
      answer,
      source: 'user_profile_recommendation'
    })
    const latest = getRecommendationQuestionState(item) || state
    const submittedIds = latest.submittedQuestionIds.includes(question.generatedQuestionId)
      ? latest.submittedQuestionIds
      : [...latest.submittedQuestionIds, question.generatedQuestionId]
    const completed = submittedIds.length >= latest.questions.length
    updateRecommendationQuestionState(item, {
      questions: latest.questions.map((itemQuestion) =>
        itemQuestion.generatedQuestionId === question.generatedQuestionId
          ? {
              ...itemQuestion,
              submitting: false,
              submitted: true,
              score: response.correctnessScore,
              level: response.level,
              briefFeedback: response.feedback
            }
          : itemQuestion
      ),
      attempts: {
        ...latest.attempts,
        [question.generatedQuestionId]: response
      },
      submittedQuestionIds: submittedIds,
      completed,
      submitError: '',
      doneNotice: completed ? '全部题目已提交，可以查看训练报告。' : ''
    })
    showToast(completed ? '本轮训练已完成' : '本题已提交')
  } catch (error) {
    const message = generatedAnswerErrorMessage(error)
    const latest = getRecommendationQuestionState(item) || state
    updateRecommendationQuestionState(item, {
      questions: latest.questions.map((itemQuestion) =>
        itemQuestion.generatedQuestionId === question.generatedQuestionId
          ? { ...itemQuestion, submitting: false }
          : itemQuestion
      ),
      submitError: message
    })
    showToast(message)
  }
}

async function loadRecommendationTrainingSummary(item: ProfileRecommendationCard) {
  const state = getRecommendationQuestionState(item)
  const userId = currentUserId.value
  if (!state?.trainingSessionId || !userId || state.summaryLoading) return
  updateRecommendationQuestionState(item, {
    summaryLoading: true,
    submitError: ''
  })
  try {
    const summary = await getTrainingSessionSummary(state.trainingSessionId, userId)
    updateRecommendationQuestionState(item, {
      summary,
      summaryLoading: false,
      completed: summary.completed,
      doneNotice: summary.completed ? '训练完成，画像已更新。' : ''
    })
    if (summary.completed) {
      await refreshProfileAfterTrainingSubmit(userId)
      showToast('训练完成，画像已更新')
    }
  } catch (error) {
    const message = extractErrorMessage(error, '训练报告加载失败，请稍后重试。')
    updateRecommendationQuestionState(item, {
      summaryLoading: false,
      submitError: message
    })
    showToast(message)
  }
}

async function handleRecommendationPracticeAction(item: ProfileRecommendationCard) {
  const state = getRecommendationQuestionState(item)
  if (!state?.trainingSessionId) {
    await generateQuestionForRecommendation(item)
    return
  }
  if (state.completed) {
    await loadRecommendationTrainingSummary(item)
    return
  }
  const nextIndex = state.questions.findIndex((question) => !question.submitted)
  updateRecommendationQuestionState(item, {
    currentIndex: nextIndex >= 0 ? nextIndex : state.currentIndex
  })
}

function getDimensionDescription(dimension: string, index: number) {
  const diagnose = trainingDiagnoseResult.value
  const point = diagnose?.weak_knowledge_points?.[index]
  const evidence = diagnose?.recent_evidence
  const aiTopics = evidence?.recent_ai_topics?.slice(0, 2).join('、')
  const errors = evidence?.recent_errors?.slice(0, 2).join('、')
  const failedTaskCount = evidence?.recent_failed_tasks?.length || 0

  if (dimension === '知识掌握' && point) {
    return `当前重点薄弱知识点为「${point.name}」，${point.reason}`
  }
  if (dimension === '自主探索' && aiTopics) {
    return `近期 AI 求助主题集中在 ${aiTopics}，建议通过针对性练习逐步摆脱卡点。`
  }
  if (dimension === '学习投入') {
    return failedTaskCount > 0 ? `近期存在 ${failedTaskCount} 个失败任务记录，训练结果会直接回流到投入度画像。` : '近期训练数据偏少，可通过专项练习补足画像证据。'
  }
  if (dimension === 'AI协同' && aiTopics) {
    return `当前协同热点集中在 ${aiTopics}，系统会继续围绕这些主题出题。`
  }
  if (dimension === '排障能力' && errors) {
    return `近期错误摘要包括 ${errors}，训练题会优先覆盖相近错误模式。`
  }
  return point?.reason || '系统根据画像、做题与实验行为综合诊断出了这一薄弱维度。'
}

function difficultyLabel(level?: string | null) {
  switch (level) {
    case 'hard':
      return '困难'
    case 'easy':
      return '简单'
    default:
      return '中等'
  }
}

function difficultyBadgeClass(level?: string | null) {
  switch (level) {
    case 'hard':
      return 'badge-error'
    case 'easy':
      return 'badge-success'
    default:
      return 'badge-warning'
  }
}

function questionTypeLabel(type: string) {
  switch (type) {
    case 'single_choice':
      return '单选题'
    case 'fill_blank':
      return '填空题'
    case 'short_answer':
      return '简答题'
    default:
      return type
  }
}

function extractErrorMessage(error: unknown, fallback: string) {
  if (error instanceof Error && error.message) {
    return error.message
  }
  return fallback
}

async function fetchDashboardData(userId: number) {
  if (!userId) return
  isLoadingDashboard.value = true
  dashboardError.value = ''
  try {
    const dashboard = await getProfileDashboard(userId)
    if (hasMeaningfulDashboardData(dashboard)) {
      userStats.value = dashboard.userStats || userStats.value
      learningProfile.value = dashboard.learningProfile || learningProfile.value
      solveRecords.value = dashboard.solveRecords || []
    } else {
      userStats.value = {
        completedCourses: 0,
        totalScore: 0,
        ranking: 0,
        activeStreak: 0
      }
      learningProfile.value = {
        skills: EMPTY_SKILLS.map((skill) => ({ ...skill })),
        tags: [],
        recentFocus: '',
        comprehensiveScore: 0,
        evaluation: '暂无学习记录'
      }
      solveRecords.value = []
      dashboardError.value = EMPTY_PROFILE_MESSAGE
    }
    dashboardLoaded.value = true
  } catch (error) {
    console.error('获取画像面板数据失败:', error)
    userStats.value = {
      completedCourses: 0,
      totalScore: 0,
      ranking: 0,
      activeStreak: 0
    }
    learningProfile.value = {
      skills: EMPTY_SKILLS.map((skill) => ({ ...skill })),
      tags: [],
      recentFocus: '',
      comprehensiveScore: 0,
      evaluation: '暂无学习记录'
      }
    solveRecords.value = []
    dashboardError.value = PROFILE_LOAD_ERROR_MESSAGE
    dashboardLoaded.value = true
  } finally {
    isLoadingDashboard.value = false
  }
}

async function fetchLatestProfileData(userId: number) {
  if (!userId) return null
  try {
    const latest = await getProfileLatest(userId)
    // 兜底：前端再次对画像数据做 mojibake 修复，避免后端编码修复遗漏
    const repaired = repairMojibakeDeep(latest)
    if (hasMeaningfulLatestProfile(repaired)) {
      pageNotice.value = ''
      latestProfile.value = repaired
      return repaired
    }
    latestProfile.value = null
    return null
  } catch (error) {
    console.error('获取最新画像失败:', error)
    pageNotice.value = PROFILE_LOAD_ERROR_MESSAGE
    latestProfile.value = null
    return null
  }
}

async function fetchCapabilityGrowth(userId: number) {
  if (!userId) return null
  capabilityGrowthLoading.value = true
  capabilityGrowthError.value = ''
  try {
    capabilityGrowth.value = await getStudentCapabilityGrowth(userId)
    return capabilityGrowth.value
  } catch (error) {
    console.error('获取能力成长数据失败:', error)
    capabilityGrowth.value = null
    capabilityGrowthError.value = extractErrorMessage(error, '能力成长数据加载失败，请稍后重试。')
    return null
  } finally {
    capabilityGrowthLoading.value = false
  }
}

async function fetchUserTrainingSessionsData(userId: number) {
  if (!userId) return []
  try {
    const response = await getUserTrainingSessions(userId)
    userTrainingSessions.value = response.sessions?.length ? response.sessions : []
    return userTrainingSessions.value
  } catch (error) {
    console.error('获取训练会话失败:', error)
    userTrainingSessions.value = []
    return userTrainingSessions.value
  }
}

async function fetchTrainingDiagnosis(userId: number) {
  if (!userId) return null
  diagnosing.value = true
  diagnoseError.value = ''
  try {
    const response = await diagnoseTraining({
      user_id: userId,
      class_id: currentClassId.value,
      course_id: currentCourseId.value,
      top_k: 3,
      question_count: 5
    })
    trainingDiagnoseResult.value = response
    return response
  } catch (error) {
    console.error('训练诊断失败:', error)
    diagnoseError.value = '当前账号暂无训练诊断数据。'
    trainingDiagnoseResult.value = createEmptyTrainingDiagnose(userId, currentClassId.value || 0, currentCourseId.value || 0)
    return trainingDiagnoseResult.value
  } finally {
    diagnosing.value = false
  }
}

async function refreshTrainingPanelData(userId: number) {
  await Promise.allSettled([
    fetchLatestProfileData(userId),
    fetchUserTrainingSessionsData(userId)
  ])
  await fetchTrainingDiagnosis(userId)
}

async function refreshProfileAfterTrainingSubmit(userId: number) {
  refreshingProfileAfterSubmit.value = true
  profileRefreshError.value = ''
  try {
    await Promise.allSettled([
      fetchDashboardData(userId),
      fetchLatestProfileData(userId),
      fetchCapabilityGrowth(userId)
    ])
    await fetchTrainingDiagnosis(userId)
  } catch (error) {
    console.error('训练后刷新画像失败:', error)
    profileRefreshError.value = extractErrorMessage(error, '训练已提交，但画像刷新暂时失败。')
  } finally {
    refreshingProfileAfterSubmit.value = false
  }
}

function buildCourseContext(points: WeakKnowledgePoint[]) {
  const grouped = new Map<number | string, { module_id?: number | null; module_name?: string | null; knowledge_snippets: string[] }>()

  for (const point of points) {
    const key = point.module_id ?? point.knowledge_point_id ?? point.name
    const item = grouped.get(key) || {
      module_id: point.module_id ?? null,
      module_name: point.module_id ? `模块 ${point.module_id}` : learningProfile.value.recentFocus || '画像推荐模块',
      knowledge_snippets: []
    }

    item.knowledge_snippets.push(point.name)
    if (point.description) item.knowledge_snippets.push(point.description)
    item.knowledge_snippets.push(point.reason)
    if (learningProfile.value.recentFocus) item.knowledge_snippets.push(`近期关注：${learningProfile.value.recentFocus}`)

    grouped.set(key, item)
  }

  return Array.from(grouped.values()).map((item) => ({
    ...item,
    knowledge_snippets: Array.from(new Set(item.knowledge_snippets)).slice(0, 5)
  }))
}

function buildTrainingQuestionState(question: GeneratedTrainingQuestion): TrainingQuestionViewModel {
  return {
    ...question,
    options: question.options || [],
    scoring_rubric: question.scoring_rubric || [],
    currentAnswer: '',
    submitting: false,
    submitted: false,
    isCorrect: null,
    score: null,
    submitError: '',
    startedAt: Date.now(),
    costTime: null,
    explanationVisible: false
  }
}

async function hydrateTrainingQuestions(trainingSessionId: string) {
  const response = await getTrainingQuestions(trainingSessionId)
  trainingQuestions.value = (response.questions || []).map(buildTrainingQuestionState)
}

async function openTeacherAssignmentSession(trainingSessionId: string) {
  if (!trainingSessionId) return
  try {
    activeTrainingSessionId.value = trainingSessionId
    await hydrateTrainingQuestions(trainingSessionId)
    showTrainingView.value = true
    window.scrollTo({ top: 0, behavior: 'smooth' })
  } catch (error) {
    showToast(extractErrorMessage(error, '教师布置的训练加载失败，请稍后重试。'))
  }
}

function generateRequestId() {
  return `training-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`
}

function getSingleChoiceValue(option: string, index: number) {
  const match = option.match(/^\s*([A-Z])[\.\u3001:：)]/)
  if (match?.[1]) {
    return match[1]
  }
  return String.fromCharCode(65 + index)
}

function normalizeAnswer(question: TrainingQuestionViewModel) {
  const answer = question.currentAnswer.trim()
  if (question.question_type === 'single_choice') {
    return answer.toUpperCase()
  }
  return answer
}

function validateAnswer(question: TrainingQuestionViewModel) {
  const answer = normalizeAnswer(question)
  if (question.question_type === 'single_choice' && !answer) {
    return '请选择一个选项后再提交。'
  }
  if (question.question_type === 'fill_blank' && !answer) {
    return '填空题答案不能为空。'
  }
  if (question.question_type === 'short_answer' && answer.length < 10) {
    return '简答题至少输入 10 个字符。'
  }
  return ''
}

function hasExplanationContent(question: TrainingQuestionViewModel) {
  return Boolean(
    question.explanation ||
    question.reference_answer ||
    question.standard_answer ||
    (question.scoring_rubric && question.scoring_rubric.length)
  )
}

function toggleExplanation(question: TrainingQuestionViewModel) {
  question.explanationVisible = !question.explanationVisible
}

async function startTraining(target?: WeakKnowledgePoint) {
  const userId = currentUserId.value
  if (!userId) {
    showToast('请先登录后再开始训练')
    return
  }

  generateError.value = ''
  generatingQuestions.value = true

  try {
    let diagnose = trainingDiagnoseResult.value
    if (!diagnose) {
      diagnose = await fetchTrainingDiagnosis(userId)
    }
    if (!diagnose) {
      throw new Error('当前还没有可用的训练诊断结果。')
    }

    const weakPoints = target ? [target] : diagnose.weak_knowledge_points
    if (!weakPoints.length) {
      throw new Error('当前没有可训练的薄弱知识点，请先完成课程学习后再试。')
    }

    const response = await generateTrainingQuestions({
      user_id: userId,
      class_id: currentClassId.value,
      course_id: currentCourseId.value,
      profile_snapshot_id: currentProfileSnapshotId.value,
      dimension_scores: diagnose.dimension_scores,
      weak_dimensions: diagnose.weak_dimensions,
      weak_knowledge_points: weakPoints,
      recent_focus: diagnose.recent_focus,
      tags: diagnose.tags,
      recent_evidence: diagnose.recent_evidence,
      question_types: ['single_choice', 'fill_blank', 'short_answer'],
      difficulty: diagnose.generation_constraints?.difficulty || 'medium',
      question_count: diagnose.generation_constraints?.question_count || 5,
      course_context: buildCourseContext(weakPoints)
    })

    activeTrainingSessionId.value = response.training_session_id
    trainingQuestions.value = (response.questions || []).map(buildTrainingQuestionState)

    if (response.training_session_id) {
      try {
        await hydrateTrainingQuestions(response.training_session_id)
      } catch (error) {
        console.warn('训练题列表回查失败，使用生成响应中的题目:', error)
      }
    }

    showTrainingView.value = true
    await nextTick()
    window.scrollTo({ top: 0, behavior: 'smooth' })
  } catch (error) {
    console.error('生成训练题失败:', error)
    generateError.value = extractErrorMessage(error, '出题失败，请稍后再试。')
    showToast(generateError.value)
  } finally {
    generatingQuestions.value = false
  }
}

async function exitTraining() {
  showTrainingView.value = false
  await nextTick()
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

async function submitQuestion(question: TrainingQuestionViewModel) {
  if (question.submitting || question.submitted) {
    return
  }

  question.submitError = ''
  const validationMessage = validateAnswer(question)
  if (validationMessage) {
    question.submitError = validationMessage
    return
  }

  question.submitting = true

  try {
    const costTime = Math.max(1, Math.round((Date.now() - question.startedAt) / 1000))
    const response = await submitTrainingAnswer({
      user_id: currentUserId.value,
      class_id: currentClassId.value,
      course_id: currentCourseId.value,
      module_id: question.module_id ?? null,
      task_id: question.task_id ?? null,
      training_session_id: activeTrainingSessionId.value,
      question_id: question.question_id,
      question_uid: question.question_id,
      question_type: question.question_type,
      answer: normalizeAnswer(question),
      knowledge_point_id: question.knowledge_point_id ?? null,
      question_score: 10,
      cost_time: costTime,
      request_id: generateRequestId(),
      auto_rebuild: true
    })

    question.submitted = true
    question.isCorrect = response.is_correct
    question.score = response.score
    question.costTime = costTime
    question.explanationVisible = true

    if (response.profile_rebuild_triggered) {
      await refreshProfileAfterTrainingSubmit(currentUserId.value)
    }

    showToast(response.message || '训练题提交成功')
  } catch (error) {
    console.error('提交训练题失败:', error)
    question.submitError = extractErrorMessage(error, '提交失败，请稍后再试。')
  } finally {
    question.submitting = false
  }
}

const openProfileModal = () => {
  editedUser.value = { ...user.value }
  avatarFile.value = null
  avatarPreviewUrl.value = ''
  avatarError.value = ''
  showProfileModal.value = true
}

const closeProfileModal = () => {
  showProfileModal.value = false
  isEditing.value = false
  avatarFile.value = null
  avatarPreviewUrl.value = ''
  avatarError.value = ''
}

const startEdit = () => {
  isEditing.value = true
}

const cancelEdit = () => {
  isEditing.value = false
  editedUser.value = { ...user.value }
  avatarFile.value = null
  avatarPreviewUrl.value = ''
  avatarError.value = ''
}

// 选择头像文件并预览
const onAvatarChange = (event: Event) => {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  avatarError.value = ''

  if (!file) return

  // 校验文件类型和大小
  if (!file.type.startsWith('image/')) {
    avatarError.value = '请选择图片文件'
    return
  }
  if (file.size > 5 * 1024 * 1024) {
    avatarError.value = '图片大小不能超过 5MB'
    return
  }

  avatarFile.value = file
  avatarPreviewUrl.value = URL.createObjectURL(file)
}

// 模态框中显示的头像预览
const modalAvatarSrc = computed(() => {
  if (avatarPreviewUrl.value) return avatarPreviewUrl.value
  const img = editedUser.value.userImage?.trim()
  return img ? resolveImage(img) : ''
})

async function saveEdit() {
  isLoading.value = true
  try {
    const token = cookie.get('token')
    if (!token) {
      showToast('请先登录')
      return
    }

    // 如果选择了新头像，先上传到 image-service
    if (avatarFile.value) {
      isUploadingAvatar.value = true
      try {
        const uploadResult = await uploadImageFile(avatarFile.value)
        const uploadedUrl = uploadResult.url || uploadResult.filename || ''
        if (uploadedUrl) {
          editedUser.value.userImage = uploadedUrl
        }
      } catch (uploadErr) {
        console.error('头像上传失败:', uploadErr)
        showToast('头像上传失败，请稍后重试')
        isUploadingAvatar.value = false
        return
      } finally {
        isUploadingAvatar.value = false
      }
    }

    const response = await updateUserInfoByToken(editedUser.value, token)
    if (response?.data) {
      const image = response.data.userImage?.trim() || ''
      user.value = { ...response.data, userImage: image }
      editedUser.value = { ...user.value }
    }

    avatarFile.value = null
    avatarPreviewUrl.value = ''
    isEditing.value = false
    showProfileModal.value = false
    showToast('保存成功')
  } catch (error) {
    console.error('保存用户信息失败:', error)
    showToast('保存失败，请稍后重试')
  } finally {
    isLoading.value = false
  }
}

async function fetchUserData() {
  isLoadingUserData.value = true
  try {
    const loginUser = getCurrentLoginUser()
    const token = cookie.get('token')
    if (!token) {
      applyEmptyProfileBundle(loginUser)
      pageNotice.value = ''
      return
    }

    const response = await getUserInfo(token)
    if (!response?.data) {
      throw new Error('未获取到用户数据')
    }

    user.value = {
      ...response.data,
      userName: response.data.userName || loginUser?.userName || loginUser?.username || '',
      userStudentNumber: response.data.userStudentNumber || loginUser?.userStudentNumber || loginUser?.studentNumber || loginUser?.studentNo || loginUser?.account || '',
      userEmail: response.data.userEmail || loginUser?.userEmail || '',
      userTel: response.data.userTel || loginUser?.userTel || loginUser?.phone || '',
      userAcademy: response.data.userAcademy || loginUser?.userAcademy || '',
      userClass: response.data.userClass || loginUser?.userClass || '',
      userImage: response.data.userImage?.trim() || ''
    }
    editedUser.value = { ...user.value }
    profileMajor.value = loginUser?.major || ''
      pageNotice.value = ''

    await Promise.allSettled([
      fetchDashboardData(user.value.userId),
      refreshTrainingPanelData(user.value.userId),
      fetchCapabilityGrowth(user.value.userId)
    ])

    if (!currentProfileSnapshotId.value && !dashboardError.value) {
      dashboardError.value = EMPTY_PROFILE_MESSAGE
    }
  } catch (error) {
    console.error('获取用户数据失败:', error)
    applyEmptyProfileBundle(getCurrentLoginUser())
    pageNotice.value = PROFILE_LOAD_ERROR_MESSAGE
  } finally {
    isLoadingUserData.value = false
  }
}

onMounted(() => {
  window.scrollTo({ top: 0, behavior: 'instant' as ScrollBehavior })

  setTimeout(() => {
    isLoaded.value = true
  }, 100)

  setTimeout(() => {
    fetchUserData()
  }, 300)
})

onBeforeUnmount(() => {
  stopGenerationElapsedTimer()
})
</script>

<template>
  <div class="container-fluid px-4 py-6 overflow-x-hidden">
    <div v-if="!showTrainingView" class="space-y-6">
      <div v-if="pageNotice" class="alert alert-warning py-3">
        <i class="fas fa-triangle-exclamation"></i>
        <span>{{ pageNotice }}</span>
      </div>

      <div
        class="card bg-base-100 shadow-xl backdrop-blur-sm border border-base-200 transition-all duration-500 overflow-hidden"
        :class="{ 'translate-y-0 opacity-100': isLoaded, 'translate-y-4 opacity-0': !isLoaded }"
      >
        <div class="card-body p-0">
          <div class="h-32 bg-gradient-to-r from-primary/20 via-secondary/20 to-accent/20 relative">
            <div class="absolute inset-0 flex items-center justify-center opacity-20">
              <i class="fas fa-brain text-7xl text-white"></i>
            </div>
          </div>

          <div class="px-6 pb-6 -mt-16">
            <div class="flex flex-col md:flex-row items-start md:items-end gap-6 mb-8">
              <div class="relative group">
                <div
                  class="avatar cursor-pointer tooltip tooltip-right tooltip-primary"
                  data-tip="点击查看或编辑个人资料"
                  @click="openProfileModal"
                >
                  <div class="w-32 h-32 md:w-36 md:h-36 rounded-full ring-4 ring-primary shadow-lg bg-base-100 flex items-center justify-center overflow-hidden">
                    <img
                      v-if="displayUserImage"
                      :src="displayUserImage"
                      alt="用户头像"
                      class="transition-transform duration-300 group-hover:scale-105 w-full h-full object-cover"
                    />
                    <i v-else class="fas fa-user text-5xl text-base-content/30"></i>
                  </div>
                </div>
                <div class="absolute -bottom-2 -right-2 bg-base-100 rounded-full p-1 shadow-lg pointer-events-none">
                  <div class="badge badge-primary">学生</div>
                </div>
              </div>

              <div class="flex-1">
                <h1 class="text-3xl font-bold mb-3 flex items-center gap-3 text-base-content/80">
                  {{ displayProfile.userName }}
                  <i class="fas fa-check-circle text-primary text-xl"></i>
                </h1>
                <div class="flex flex-wrap gap-4 text-base-content/70">
                  <div class="flex items-center gap-2 bg-base-200/60 px-3 py-2 rounded-lg">
                    <i class="fas fa-id-card text-primary"></i>
                    <span class="font-medium">{{ displayProfile.studentNo }}</span>
                  </div>
                  <div class="flex items-center gap-2 bg-base-200/60 px-3 py-2 rounded-lg">
                    <i class="fas fa-graduation-cap text-primary"></i>
                    <span class="font-medium">{{ displayProfile.college }}</span>
                  </div>
                  <div class="flex items-center gap-2 bg-base-200/60 px-3 py-2 rounded-lg">
                    <i class="fas fa-users text-primary"></i>
                    <span class="font-medium">{{ displayProfile.className }}</span>
                  </div>
                  <div class="flex items-center gap-2 bg-base-200/60 px-3 py-2 rounded-lg">
                    <i class="fas fa-user-shield text-primary"></i>
                    <span class="font-medium">{{ displayProfile.major }}</span>
                  </div>
                  <div class="flex items-center gap-2 bg-base-200/60 px-3 py-2 rounded-lg">
                    <i class="fas fa-envelope text-primary"></i>
                    <span class="font-medium">{{ displayProfile.email }}</span>
                  </div>
                  <div class="flex items-center gap-2 bg-base-200/60 px-3 py-2 rounded-lg">
                    <i class="fas fa-phone text-primary"></i>
                    <span class="font-medium">{{ displayProfile.phone }}</span>
                  </div>
                  <div class="flex items-center gap-2 bg-base-200/60 px-3 py-2 rounded-lg">
                    <i class="fas fa-clock text-primary"></i>
                    <span class="font-medium">连续学习 {{ activeStreakDays }} 天</span>
                  </div>
                </div>
              </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
              <div class="stat bg-base-200/50 rounded-box p-4">
                <div class="stat-figure text-primary">
                  <i class="fas fa-brain text-3xl"></i>
                </div>
                <div class="stat-title">AI 学习力</div>
                <div class="stat-value text-primary">{{ userStats.totalScore }}</div>
              </div>
              <div class="stat bg-base-200/50 rounded-box p-4">
                <div class="stat-figure text-secondary">
                  <i class="fas fa-flask text-3xl"></i>
                </div>
                <div class="stat-title">完成实验</div>
                <div class="stat-value text-secondary">{{ userStats.completedCourses }}</div>
              </div>
              <div class="stat bg-base-200/50 rounded-box p-4">
                <div class="stat-figure text-accent">
                  <i class="fas fa-robot text-3xl"></i>
                </div>
                <div class="stat-title">AI 协同</div>
                <div class="stat-value text-accent">{{ aiCollaborationScore }}</div>
              </div>
              <div class="stat bg-base-200/50 rounded-box p-4">
                <div class="stat-figure text-success">
                  <i class="fas fa-trophy text-3xl"></i>
                </div>
                <div class="stat-title">班级排名</div>
                <div class="stat-value text-success">{{ classRankText }}</div>
              </div>
            </div>

            <div class="grid grid-cols-1 xl:grid-cols-4 gap-4 mb-8">
              <div v-for="card in profileOverviewCards" :key="card.title" class="rounded-2xl border border-base-200 bg-base-100/80 p-4 shadow-sm">
                <div class="flex items-start justify-between gap-3">
                  <div class="flex-1">
                    <div class="text-sm text-base-content/60">{{ card.title }}</div>
                    <div class="mt-2 text-lg font-bold text-base-content">{{ card.value }}</div>
                    <div class="mt-2 text-xs leading-5 text-base-content/60">{{ card.desc }}</div>
                  </div>
                  <i :class="['fas', card.icon, card.iconClass, 'text-2xl']"></i>
                </div>
                <div class="mt-4">
                  <span class="badge badge-sm" :class="card.badgeClass">{{ card.badge }}</span>
                </div>
              </div>
            </div>

            <div v-if="isLoadingUserData" class="text-sm text-base-content/60">
              正在同步用户资料...
            </div>
            <div v-if="isLoadingDashboard" class="text-sm text-base-content/60">
              正在加载画像面板数据...
            </div>
            <div v-else-if="dashboardError" class="text-sm text-warning">
              {{ dashboardError }}
            </div>
          </div>
        </div>
      </div>

      <CapabilityGrowthPanel
        :data="capabilityGrowth"
        :loading="capabilityGrowthLoading"
        :error="capabilityGrowthError"
        @retry="fetchCapabilityGrowth(currentUserId)"
      />

      <TeacherAssignments :user-id="currentUserId" @open-session="openTeacherAssignmentSession" />

      <div class="card bg-base-100 shadow-xl mt-6">
        <div class="card-body">
          <h2 class="text-xl font-semibold mb-6">
            <i class="fas fa-chart-pie text-secondary mr-2"></i>
            AI 学习画像分析
          </h2>
          <div v-if="isLoadingDashboard" class="text-sm text-base-content/60 mb-4">
            正在同步数据库画像...
          </div>
          <div v-else-if="!dashboardLoaded && !dashboardError" class="text-sm text-base-content/60 mb-4">
            当前画像快照正在生成中，系统会根据最近学习与训练表现自动更新分析结果。
          </div>

          <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <div class="flex flex-col items-center justify-center p-6 bg-base-200/50 rounded-box">
              <div
                class="radial-progress text-primary mb-6 bg-base-100 border-4 border-base-200"
                :style="`--value:${learningProfile.comprehensiveScore}; --size:9rem; --thickness: 0.8rem;`"
              >
                <span class="text-3xl font-bold">{{ learningProfile.comprehensiveScore }}</span>
                <span class="text-sm opacity-70 block -mt-1">AI 学习力</span>
              </div>

              <h3 class="text-lg font-medium mb-4 w-full text-center border-b border-base-300 pb-2">学习标签</h3>
              <div class="flex flex-wrap gap-2 justify-center w-full">
                <div
                  v-for="(tag, index) in displayTags"
                  :key="index"
                  class="badge badge-outline shadow-sm p-3 font-medium"
                  :class="tag.type"
                >
                  <i class="fas fa-tag mr-1 text-xs opacity-70"></i>
                  {{ tag.text }}
                </div>
              </div>
            </div>

            <div class="lg:col-span-2 p-6 bg-base-200/50 rounded-box flex flex-col justify-center">
              <h3 class="text-lg font-medium mb-6 flex items-center">
                <i class="fas fa-layer-group text-primary mr-2"></i>
                AI 能力维度
              </h3>
              <div class="space-y-5 w-full">
                <div v-for="(skill, index) in learningProfile.skills" :key="index" class="group">
                  <div class="flex justify-between mb-2">
                    <span class="text-sm font-semibold opacity-80 group-hover:opacity-100 transition-opacity">{{ skill.name }}</span>
                    <span class="text-sm font-bold" :class="skill.color">{{ skill.score }}/100</span>
                  </div>
                  <progress
                    class="progress w-full h-3 bg-base-300"
                    :class="skill.color.replace('text-', 'progress-')"
                    :value="skill.score"
                    max="100"
                  ></progress>
                </div>
              </div>
            </div>
          </div>

          <div class="mt-6 p-5 bg-info/10 rounded-box border border-info/20 shadow-sm">
            <h3 class="text-md font-semibold text-info mb-3 flex items-center">
              <i class="fas fa-comment-dots mr-2 text-lg"></i> AI 学习建议
            </h3>
            <p class="text-sm text-base-content/80 leading-relaxed indent-7">
              {{ learningProfile.evaluation }}
            </p>
            <div class="mt-4 pt-3 border-t border-info/20 text-sm flex items-center gap-2 flex-wrap">
              <i class="fas fa-bullseye text-primary"></i>
              <span class="font-medium text-base-content/70">近期学习重点:</span>
              <span class="badge badge-primary badge-sm font-semibold">{{ learningProfile.recentFocus || '待生成' }}</span>
            </div>
          </div>
        </div>
      </div>

      <div class="card bg-base-100 shadow-xl mt-6 relative overflow-hidden border border-primary/20">
        <div class="absolute -right-16 -top-16 opacity-[0.03] pointer-events-none">
          <i class="fas fa-brain" style="font-size: 20rem;"></i>
        </div>

        <div class="card-body relative z-10">
          <div class="flex items-center justify-between gap-4 flex-wrap mb-4">
            <h2 class="text-xl font-semibold flex items-center gap-2">
              <i class="fas fa-robot text-primary text-2xl animate-pulse"></i>
              AI 专属强化练习
            </h2>
            <button
              class="btn btn-primary btn-sm badge-outline shadow-sm gap-2 p-3 font-medium transition-transform hover:-translate-y-1"
              :disabled="generatingQuestions || diagnosing"
              @click="startTraining()"
              title="完成个性化训练后，画像分数、标签和推荐内容会自动刷新。"
            >
              <i class="fas" :class="generatingQuestions ? 'fa-spinner fa-spin' : 'fa-rocket'"></i>
              {{ generatingQuestions ? '正在生成题目...' : '开始练习' }}
            </button>
          </div>

          <p class="text-sm text-base-content/80 mb-4 leading-relaxed">
            系统会根据你的答题记录、实验完成情况和常见错误，生成适合当前阶段的强化练习。完成练习后，个人画像会同步更新，帮助你看到自己的进步。
          </p>
          <p class="text-xs text-base-content/60 mb-6">
            {{ recentTrainingSummary }}
          </p>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
            <div v-for="item in recentTrainingCards" :key="item.id" class="rounded-2xl border border-base-200 bg-base-100/70 p-4 shadow-sm">
              <div class="text-sm font-semibold text-base-content">{{ item.title }}</div>
              <div class="mt-1 text-xs text-base-content/50">{{ item.time }}</div>
              <div class="mt-3 text-sm leading-6 text-base-content/70">{{ item.desc }}</div>
            </div>
          </div>

          <div v-if="diagnosing" class="alert alert-info mb-4 py-3">
            <i class="fas fa-spinner fa-spin"></i>
            <span>正在分析最新画像、近期做题与实验行为...</span>
          </div>
          <div v-if="diagnoseError" class="alert alert-warning mb-4 py-3">
            <i class="fas fa-triangle-exclamation"></i>
            <span>{{ diagnoseError }}</span>
          </div>
          <div v-if="generateError" class="alert alert-error mb-4 py-3">
            <i class="fas fa-circle-exclamation"></i>
            <span>{{ generateError }}</span>
          </div>

          <h3 class="text-sm font-bold text-base-content/60 uppercase tracking-widest mb-3">
            <i class="fas fa-chart-line mr-1"></i> 学习薄弱点分析
          </h3>
          <div v-if="profileAnalysisDimensions.length" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
            <div
              v-for="dimension in profileAnalysisDimensions"
              :key="dimension.label"
              class="bg-base-200/50 p-4 rounded-xl flex items-start gap-4 border-l-4 hover:bg-base-200/90 transition-all cursor-default shadow-sm"
              :class="dimension.borderClass"
            >
              <i :class="['fas', dimension.icon, 'text-xl mt-0.5 opacity-80', dimension.iconClass]"></i>
              <div>
                <div class="font-bold text-sm mb-1.5">{{ dimension.label }}</div>
                <div class="text-[0.7rem] text-base-content/70 leading-relaxed">{{ dimension.desc }}</div>
              </div>
            </div>
          </div>
          <div v-else class="text-sm text-base-content/60 mb-8 bg-base-200/40 rounded-box p-4">
            当前尚未拉开明显的弱项差距，系统会继续结合实验记录、作答结果和 AI 协同主题更新推荐方向。
          </div>

          <h3 class="text-sm font-bold text-base-content/60 uppercase tracking-widest mb-3">
            <i class="fas fa-fire-alt text-error mr-1"></i> 推荐强化任务
          </h3>
          <div v-if="profileRecommendations.length" class="space-y-4">
            <div
              v-for="recommendation in profileRecommendations"
              :key="recommendation.id"
              class="border border-base-200 hover:border-primary/50 transition-all p-5 rounded-box flex flex-col md:flex-row flex-wrap gap-5 items-start md:items-center bg-gradient-to-r from-base-100 to-base-200/30 hover:shadow-md group"
            >
              <div class="flex-1 w-full relative">
                <div class="flex items-center gap-3 mb-2 flex-wrap">
                  <h4 class="text-lg font-bold text-base-content/90">{{ recommendation.title }}</h4>
                  <div class="badge badge-sm font-medium" :class="recommendation.priorityClass">{{ recommendation.priorityLabel }}</div>
                  <div class="badge badge-sm badge-ghost border-base-300">{{ recommendation.dimensionName }}</div>
                  <div class="badge badge-sm badge-outline">当前得分 {{ recommendation.scoreText }}</div>
                  <div class="badge badge-sm badge-outline">{{ recommendation.resourceTypeLabel }}</div>
                  <div class="badge badge-sm badge-outline">{{ recommendation.difficultyText }}</div>
                </div>

                <p class="text-xs md:text-sm text-base-content/80 mt-3 mb-4 bg-primary/5 p-3 rounded-lg border border-primary/10 leading-relaxed">
                  <i class="fas fa-lightbulb text-accent mr-1"></i>
                  <strong class="text-base-content/90">推荐原因：</strong>{{ recommendation.reason }}
                </p>

                <div class="flex flex-wrap gap-2">
                  <span
                    v-for="tag in recommendation.tags"
                    :key="tag"
                    class="text-[0.65rem] font-bold tracking-wider bg-base-200 text-base-content/60 px-2 py-1 rounded"
                  >
                    #{{ tag }}
                  </span>
                </div>
              </div>

              <div class="w-full md:w-56 mt-2 md:mt-0 flex-shrink-0 rounded-box border border-base-200 bg-base-200/50 p-4 space-y-3">
                <div>
                  <div class="text-xs font-bold uppercase tracking-wider text-base-content/50 mb-2">建议动作</div>
                  <div class="text-sm text-base-content/80 leading-relaxed">{{ recommendation.action }}</div>
                </div>
                <button
                  class="btn btn-primary btn-sm w-full"
                  :disabled="recommendation.actionDisabled"
                  :title="recommendation.actionHint"
                  @click="openRecommendationResource(recommendation)"
                >
                  {{ recommendation.actionDisabled ? recommendation.actionHint : recommendation.actionText }}
                </button>
                <button
                  class="btn btn-accent btn-sm w-full"
                  :disabled="Boolean(generatingRecommendationId && !isGeneratingRecommendationQuestion(recommendation)) || !canGenerateRecommendationQuestion(recommendation)"
                  @click="handleRecommendationPracticeAction(recommendation)"
                >
                  <i
                    class="fas"
                    :class="isGeneratingRecommendationQuestion(recommendation) ? 'fa-spinner fa-spin' : 'fa-wand-magic-sparkles'"
                  ></i>
                  {{ recommendationPracticeButtonLabel(recommendation) }}
                </button>
                <div
                  v-if="isGeneratingRecommendationQuestion(recommendation) || getRecommendationQuestionState(recommendation)?.loading"
                  class="text-xs text-base-content/60 leading-relaxed"
                >
                  {{ trainingWaitMessage(generationElapsedSeconds, RECOMMENDATION_PRACTICE_COUNT) }}
                </div>
              </div>

              <div v-if="getRecommendationQuestionState(recommendation)?.error" class="w-full rounded-box border border-error/20 bg-error/10 p-4 text-sm text-error">
                {{ getRecommendationQuestionState(recommendation)?.error }}
              </div>

              <div
                v-if="getRecommendationQuestionState(recommendation)?.trainingSessionId"
                class="w-full rounded-box border border-accent/20 bg-base-100/90 p-4 space-y-4"
              >
                <div class="flex items-start justify-between gap-3 flex-wrap">
                  <div>
                    <div class="text-xs font-bold uppercase tracking-wider text-accent mb-1">推荐训练板块</div>
                    <h4 class="text-base font-bold text-base-content/90">{{ recommendation.title }}</h4>
                    <div class="mt-2 flex flex-wrap gap-2 text-xs">
                      <span class="badge badge-accent badge-outline">本轮训练共 {{ getRecommendationQuestionState(recommendation)?.questions.length || RECOMMENDATION_PRACTICE_COUNT }} 题</span>
                      <span class="badge badge-outline">
                        已完成 {{ getRecommendationQuestionState(recommendation)?.submittedQuestionIds.length || 0 }} / {{ getRecommendationQuestionState(recommendation)?.questions.length || RECOMMENDATION_PRACTICE_COUNT }}
                      </span>
                    </div>
                  </div>
                  <button
                    v-if="getRecommendationQuestionState(recommendation)?.completed"
                    class="btn btn-outline btn-sm"
                    :disabled="getRecommendationQuestionState(recommendation)?.summaryLoading"
                    @click="loadRecommendationTrainingSummary(recommendation)"
                  >
                    <i class="fas" :class="getRecommendationQuestionState(recommendation)?.summaryLoading ? 'fa-spinner fa-spin' : 'fa-chart-column'"></i>
                    {{ getRecommendationQuestionState(recommendation)?.summaryLoading ? '报告生成中...' : '查看训练报告' }}
                  </button>
                </div>

                <div v-if="getRecommendationQuestionState(recommendation)?.doneNotice" class="alert alert-success py-3">
                  <i class="fas fa-circle-check"></i>
                  <span>{{ getRecommendationQuestionState(recommendation)?.doneNotice }}</span>
                </div>

                <template v-if="!getRecommendationQuestionState(recommendation)?.summary">
                  <div v-if="currentRecommendationQuestion(getRecommendationQuestionState(recommendation))" class="rounded-box border border-base-300 bg-base-200/30 p-4 space-y-4">
                    <div class="flex items-start justify-between gap-3 flex-wrap">
                      <div>
                        <div class="text-sm font-semibold text-base-content/70">
                          第 {{ (getRecommendationQuestionState(recommendation)?.currentIndex || 0) + 1 }} /
                          {{ getRecommendationQuestionState(recommendation)?.questions.length || RECOMMENDATION_PRACTICE_COUNT }} 题
                        </div>
                        <h5 class="text-base font-bold mt-1">
                          {{ currentRecommendationQuestion(getRecommendationQuestionState(recommendation))?.title }}
                        </h5>
                      </div>
                      <div class="flex flex-wrap gap-2">
                        <span class="badge badge-accent badge-outline">
                          {{ currentRecommendationQuestion(getRecommendationQuestionState(recommendation))?.questionType }}
                        </span>
                        <span class="badge badge-outline">
                          难度 {{ currentRecommendationQuestion(getRecommendationQuestionState(recommendation))?.difficulty }}
                        </span>
                      </div>
                    </div>

                    <p class="text-sm text-base-content/80 leading-7 whitespace-pre-wrap">
                      {{ currentRecommendationQuestion(getRecommendationQuestionState(recommendation))?.stem }}
                    </p>

                    <div class="flex flex-wrap gap-2">
                      <span
                        v-for="tag in currentRecommendationQuestion(getRecommendationQuestionState(recommendation))?.knowledgeTags || []"
                        :key="`${recommendation.id}-set-tag-${tag}`"
                        class="text-[0.65rem] font-bold tracking-wider bg-accent/10 text-accent px-2 py-1 rounded"
                      >
                        #{{ tag }}
                      </span>
                    </div>

                    <label class="form-control">
                      <div class="label">
                        <span class="label-text font-semibold">输入你的答案</span>
                      </div>
                      <textarea
                        :value="currentRecommendationAnswer(getRecommendationQuestionState(recommendation))"
                        class="textarea textarea-bordered min-h-28 text-sm"
                        placeholder="请输入你的答案"
                        :disabled="Boolean(currentRecommendationQuestion(getRecommendationQuestionState(recommendation))?.submitted || currentRecommendationQuestion(getRecommendationQuestionState(recommendation))?.submitting)"
                        @input="updateRecommendationStudentAnswer(recommendation, ($event.target as HTMLTextAreaElement).value)"
                      ></textarea>
                    </label>

                    <div v-if="getRecommendationQuestionState(recommendation)?.submitError" class="text-sm text-error">
                      {{ getRecommendationQuestionState(recommendation)?.submitError }}
                    </div>

                    <div
                      v-if="currentRecommendationQuestion(getRecommendationQuestionState(recommendation))?.submitted"
                      class="rounded-box border border-success/20 bg-success/5 p-4 space-y-2"
                    >
                      <div class="flex flex-wrap items-center gap-2">
                        <span class="font-semibold">本题已提交</span>
                        <span class="badge badge-outline">
                          得分 {{ currentRecommendationQuestion(getRecommendationQuestionState(recommendation))?.score ?? 0 }}/100
                        </span>
                        <span class="badge" :class="feedbackLevelClass(currentRecommendationQuestion(getRecommendationQuestionState(recommendation))?.level)">
                          {{ feedbackLevelLabel(currentRecommendationQuestion(getRecommendationQuestionState(recommendation))?.level) }}
                        </span>
                      </div>
                      <div class="text-sm text-base-content/80 whitespace-pre-wrap">
                        {{ currentRecommendationQuestion(getRecommendationQuestionState(recommendation))?.briefFeedback }}
                      </div>
                    </div>

                    <div class="flex flex-wrap gap-2">
                      <button
                        v-if="!currentRecommendationQuestion(getRecommendationQuestionState(recommendation))?.submitted"
                        class="btn btn-primary btn-sm"
                        :disabled="Boolean(currentRecommendationQuestion(getRecommendationQuestionState(recommendation))?.submitting)"
                        @click="submitRecommendationAnswer(recommendation)"
                      >
                        <i
                          class="fas"
                          :class="currentRecommendationQuestion(getRecommendationQuestionState(recommendation))?.submitting ? 'fa-spinner fa-spin' : 'fa-paper-plane'"
                        ></i>
                        {{ currentRecommendationQuestion(getRecommendationQuestionState(recommendation))?.submitting ? '提交中...' : '提交答案' }}
                      </button>
                      <button
                        v-else-if="!isLastRecommendationQuestion(getRecommendationQuestionState(recommendation))"
                        class="btn btn-accent btn-sm"
                        @click="goToNextRecommendationQuestion(recommendation)"
                      >
                        继续下一题
                      </button>
                      <button
                        v-else
                        class="btn btn-accent btn-sm"
                        :disabled="getRecommendationQuestionState(recommendation)?.summaryLoading"
                        @click="loadRecommendationTrainingSummary(recommendation)"
                      >
                        <i class="fas" :class="getRecommendationQuestionState(recommendation)?.summaryLoading ? 'fa-spinner fa-spin' : 'fa-chart-column'"></i>
                        {{ getRecommendationQuestionState(recommendation)?.summaryLoading ? '报告生成中...' : '查看训练报告' }}
                      </button>
                    </div>
                  </div>
                </template>

                <div v-if="getRecommendationQuestionState(recommendation)?.summary" class="rounded-box border border-primary/20 bg-primary/5 p-4 space-y-4">
                  <div class="flex items-center justify-between gap-3 flex-wrap">
                    <div>
                      <div class="text-sm font-semibold text-base-content/70">训练报告</div>
                      <div class="text-xl font-bold mt-1">
                        平均分 {{ getRecommendationQuestionState(recommendation)?.summary?.averageScore }}/100
                      </div>
                    </div>
                    <div class="flex flex-wrap gap-2">
                      <span class="badge badge-outline">总题数 {{ getRecommendationQuestionState(recommendation)?.summary?.totalQuestions }}</span>
                      <span class="badge badge-outline">已完成 {{ getRecommendationQuestionState(recommendation)?.summary?.submittedCount }}</span>
                      <span class="badge" :class="feedbackLevelClass(getRecommendationQuestionState(recommendation)?.summary?.level)">
                        {{ feedbackLevelLabel(getRecommendationQuestionState(recommendation)?.summary?.level) }}
                      </span>
                    </div>
                  </div>

                  <div v-if="getRecommendationQuestionState(recommendation)?.summary?.summaryFeedback" class="text-sm text-base-content/80 whitespace-pre-wrap">
                    {{ getRecommendationQuestionState(recommendation)?.summary?.summaryFeedback }}
                  </div>
                  <ul v-if="getRecommendationQuestionState(recommendation)?.summary?.nextActions?.length" class="list-disc pl-5 text-sm text-base-content/75 space-y-1">
                    <li v-for="action in getRecommendationQuestionState(recommendation)?.summary?.nextActions || []" :key="`${recommendation.id}-next-${action}`">
                      {{ action }}
                    </li>
                  </ul>

                  <div class="space-y-3">
                    <div
                      v-for="(item, index) in getRecommendationQuestionState(recommendation)?.summary?.questions || []"
                      :key="item.generatedQuestionId"
                      class="rounded-box border border-base-300 bg-base-100/80"
                    >
                      <button
                        class="w-full text-left p-4 flex items-center justify-between gap-3"
                        @click="toggleSummaryQuestion(recommendation, item.generatedQuestionId)"
                      >
                        <span class="font-semibold">第 {{ index + 1 }} 题：{{ item.title }}</span>
                        <span class="flex items-center gap-2">
                          <span class="badge badge-outline">{{ item.correctnessScore ?? 0 }}/100</span>
                          <i class="fas fa-chevron-down"></i>
                        </span>
                      </button>
                      <div
                        v-if="getRecommendationQuestionState(recommendation)?.questions.find((question) => question.generatedQuestionId === item.generatedQuestionId)?.expanded"
                        class="px-4 pb-4 space-y-3 text-sm"
                      >
                        <div class="whitespace-pre-wrap text-base-content/80">{{ item.stem }}</div>
                        <div>
                          <div class="font-semibold mb-1">学生答案</div>
                          <div class="whitespace-pre-wrap text-base-content/75">{{ item.studentAnswer || '未提交' }}</div>
                        </div>
                        <div v-if="item.feedback">
                          <div class="font-semibold mb-1">反馈</div>
                          <div class="whitespace-pre-wrap text-base-content/75">{{ item.feedback }}</div>
                        </div>
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                          <div>
                            <div class="font-semibold text-success mb-1">命中项</div>
                            <ul class="list-disc pl-5 space-y-1">
                              <li v-for="hit in item.hitRubricItems" :key="`${item.generatedQuestionId}-hit-${hit.point}`">{{ hit.point }}（{{ hit.score }} 分）</li>
                              <li v-if="!item.hitRubricItems.length">暂无</li>
                            </ul>
                          </div>
                          <div>
                            <div class="font-semibold text-warning mb-1">遗漏项</div>
                            <ul class="list-disc pl-5 space-y-1">
                              <li v-for="miss in item.missedRubricItems" :key="`${item.generatedQuestionId}-miss-${miss.point}`">{{ miss.point }}（{{ miss.score }} 分）</li>
                              <li v-if="!item.missedRubricItems.length">暂无</li>
                            </ul>
                          </div>
                        </div>
                        <div>
                          <div class="font-semibold mb-1">标准答案</div>
                          <div class="whitespace-pre-wrap text-base-content/75">{{ item.standardAnswer }}</div>
                        </div>
                        <div>
                          <div class="font-semibold mb-1">题目解析</div>
                          <div class="whitespace-pre-wrap text-base-content/75">{{ item.explanation }}</div>
                        </div>
                        <div class="rounded border border-info/20 bg-info/5 p-3 space-y-2">
                          <div class="font-semibold">教学分析</div>
                          <div v-if="item.teachingObjective" class="whitespace-pre-wrap">教学目标：{{ item.teachingObjective }}</div>
                          <div v-if="item.expectedSkill" class="whitespace-pre-wrap">能力点：{{ item.expectedSkill }}</div>
                          <div v-if="item.difficultyReason" class="whitespace-pre-wrap">难度依据：{{ item.difficultyReason }}</div>
                          <div v-if="item.commonMistakes?.length">常见错误：{{ item.commonMistakes.join('；') }}</div>
                          <div v-if="item.gradingRubric?.length">
                            <div class="font-semibold mt-2">评分规则</div>
                            <ul class="list-disc pl-5 space-y-1">
                              <li v-for="rubric in item.gradingRubric" :key="`${item.generatedQuestionId}-rubric-${rubric.point}`">
                                {{ rubric.point }}（{{ rubric.score }} 分）
                              </li>
                            </ul>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <div
                v-if="getRecommendationQuestionState(recommendation)?.question"
                class="w-full rounded-box border border-accent/20 bg-base-100/90 p-4 space-y-4"
              >
                <div class="flex items-start justify-between gap-3 flex-wrap">
                  <div>
                    <div class="text-xs font-bold uppercase tracking-wider text-accent mb-1">AI 生成训练题</div>
                    <h4 class="text-base font-bold text-base-content/90">
                      {{ getRecommendationQuestionState(recommendation)?.question?.title }}
                    </h4>
                  </div>
                  <div class="flex flex-wrap gap-2">
                    <span class="badge badge-accent badge-outline">
                      {{ getRecommendationQuestionState(recommendation)?.question?.questionType }}
                    </span>
                    <span class="badge badge-outline">
                      难度 {{ getRecommendationQuestionState(recommendation)?.question?.difficulty }}
                    </span>
                    <span class="badge badge-ghost">
                      {{ getRecommendationQuestionState(recommendation)?.generatedQuestionId }}
                    </span>
                  </div>
                </div>

                <p class="text-sm text-base-content/80 leading-7 whitespace-pre-wrap">
                  {{ getRecommendationQuestionState(recommendation)?.question?.stem }}
                </p>

                <div class="flex flex-wrap gap-2">
                  <span
                    v-for="tag in getRecommendationQuestionState(recommendation)?.question?.knowledgeTags || []"
                    :key="`${recommendation.id}-generated-${tag}`"
                    class="text-[0.65rem] font-bold tracking-wider bg-accent/10 text-accent px-2 py-1 rounded"
                  >
                    #{{ tag }}
                  </span>
                </div>

                <div class="rounded-box border border-base-300 bg-base-200/30 p-4 space-y-3">
                  <label class="form-control">
                    <div class="label">
                      <span class="label-text font-semibold">输入你的答案</span>
                    </div>
                    <textarea
                      :value="getRecommendationQuestionState(recommendation)?.studentAnswer || ''"
                      class="textarea textarea-bordered min-h-28 text-sm"
                      placeholder="请输入你的答案"
                      :disabled="Boolean(getRecommendationQuestionState(recommendation)?.submittingAnswer || getRecommendationQuestionState(recommendation)?.feedback)"
                      @input="updateRecommendationStudentAnswer(recommendation, ($event.target as HTMLTextAreaElement).value)"
                    ></textarea>
                  </label>

                  <div v-if="getRecommendationQuestionState(recommendation)?.submitError" class="text-sm text-error">
                    {{ getRecommendationQuestionState(recommendation)?.submitError }}
                  </div>

                  <button
                    class="btn btn-primary btn-sm"
                    :disabled="Boolean(getRecommendationQuestionState(recommendation)?.submittingAnswer || getRecommendationQuestionState(recommendation)?.feedback)"
                    @click="submitRecommendationAnswer(recommendation)"
                  >
                    <i
                      class="fas"
                      :class="getRecommendationQuestionState(recommendation)?.submittingAnswer ? 'fa-spinner fa-spin' : 'fa-paper-plane'"
                    ></i>
                    {{ getRecommendationQuestionState(recommendation)?.submittingAnswer ? '提交中...' : '提交答案' }}
                  </button>

                  <div
                    v-if="getRecommendationQuestionState(recommendation)?.feedback"
                    class="rounded-box border border-success/20 bg-success/5 p-4 space-y-3"
                  >
                    <div class="flex flex-wrap items-center gap-2">
                      <span class="text-sm font-semibold">评分反馈</span>
                      <span class="badge badge-outline">
                        {{ getRecommendationQuestionState(recommendation)?.feedback?.correctnessScore }}/100
                      </span>
                      <span class="badge" :class="feedbackLevelClass(getRecommendationQuestionState(recommendation)?.feedback?.level)">
                        {{ feedbackLevelLabel(getRecommendationQuestionState(recommendation)?.feedback?.level) }}
                      </span>
                    </div>
                    <div class="text-sm text-base-content/80 whitespace-pre-wrap">
                      {{ getRecommendationQuestionState(recommendation)?.feedback?.feedback }}
                    </div>

                    <div v-if="getRecommendationQuestionState(recommendation)?.feedback?.hitRubricItems?.length">
                      <div class="text-sm font-semibold text-success mb-1">已命中评分点</div>
                      <ul class="list-disc pl-5 text-sm text-base-content/75 space-y-1">
                        <li
                          v-for="item in getRecommendationQuestionState(recommendation)?.feedback?.hitRubricItems || []"
                          :key="`${recommendation.id}-hit-${item.point}`"
                        >
                          {{ item.point }}（{{ item.score }} 分）
                        </li>
                      </ul>
                    </div>

                    <div v-if="getRecommendationQuestionState(recommendation)?.feedback?.missedRubricItems?.length">
                      <div class="text-sm font-semibold text-warning mb-1">待补充评分点</div>
                      <ul class="list-disc pl-5 text-sm text-base-content/75 space-y-1">
                        <li
                          v-for="item in getRecommendationQuestionState(recommendation)?.feedback?.missedRubricItems || []"
                          :key="`${recommendation.id}-miss-${item.point}`"
                        >
                          {{ item.point }}（{{ item.score }} 分）
                        </li>
                      </ul>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-3 text-sm">
                      <div>
                        <div class="font-semibold text-base-content/80 mb-1">命中关键词</div>
                        <div class="text-base-content/70">
                          {{ getRecommendationQuestionState(recommendation)?.feedback?.keywordHits?.join('、') || '暂无' }}
                        </div>
                      </div>
                      <div>
                        <div class="font-semibold text-base-content/80 mb-1">遗漏关键词</div>
                        <div class="text-base-content/70">
                          {{ getRecommendationQuestionState(recommendation)?.feedback?.keywordMisses?.join('、') || '暂无' }}
                        </div>
                      </div>
                    </div>

                    <div v-if="getRecommendationQuestionState(recommendation)?.feedback?.suggestion" class="text-sm text-base-content/80 whitespace-pre-wrap">
                      <span class="font-semibold">建议：</span>{{ getRecommendationQuestionState(recommendation)?.feedback?.suggestion }}
                    </div>
                  </div>
                </div>

                <div class="flex flex-wrap gap-2">
                  <button class="btn btn-ghost btn-sm" @click="toggleRecommendationTeachingAnalysis(recommendation)">
                    <i class="fas fa-chalkboard-user"></i>
                    {{ getRecommendationQuestionState(recommendation)?.teachingAnalysisVisible ? '收起教学分析' : '查看教学分析' }}
                  </button>
                  <button class="btn btn-ghost btn-sm" @click="toggleRecommendationAnswer(recommendation)">
                    <i class="fas fa-book-open"></i>
                    {{ getRecommendationQuestionState(recommendation)?.answerVisible ? '收起答案与解析' : '查看答案与解析' }}
                  </button>
                </div>

                <div
                  v-if="getRecommendationQuestionState(recommendation)?.teachingAnalysisVisible"
                  class="rounded-box border border-info/20 bg-info/5 p-4 space-y-3 training-teaching-analysis"
                >
                  <template v-if="hasRecommendationTeachingAnalysis(getRecommendationQuestionState(recommendation)?.question)">
                    <div v-if="getRecommendationQuestionState(recommendation)?.question?.teachingObjective">
                      <div class="text-sm font-semibold text-base-content/80 mb-1">教学目标</div>
                      <div class="text-sm text-base-content/75 whitespace-pre-wrap">
                        {{ getRecommendationQuestionState(recommendation)?.question?.teachingObjective }}
                      </div>
                    </div>
                    <div v-if="getRecommendationQuestionState(recommendation)?.question?.expectedSkill">
                      <div class="text-sm font-semibold text-base-content/80 mb-1">能力点</div>
                      <div class="text-sm text-base-content/75 whitespace-pre-wrap">
                        {{ getRecommendationQuestionState(recommendation)?.question?.expectedSkill }}
                      </div>
                    </div>
                    <div v-if="getRecommendationQuestionState(recommendation)?.question?.difficultyReason">
                      <div class="text-sm font-semibold text-base-content/80 mb-1">难度依据</div>
                      <div class="text-sm text-base-content/75 whitespace-pre-wrap">
                        {{ getRecommendationQuestionState(recommendation)?.question?.difficultyReason }}
                      </div>
                    </div>
                    <div v-if="getRecommendationQuestionState(recommendation)?.question?.commonMistakes?.length">
                      <div class="text-sm font-semibold text-base-content/80 mb-1">常见错误</div>
                      <ul class="list-disc pl-5 text-sm text-base-content/75 space-y-1">
                        <li
                          v-for="mistake in getRecommendationQuestionState(recommendation)?.question?.commonMistakes || []"
                          :key="`${recommendation.id}-mistake-${mistake}`"
                        >
                          {{ mistake }}
                        </li>
                      </ul>
                    </div>
                    <div v-if="getRecommendationQuestionState(recommendation)?.question?.gradingRubric?.length">
                      <div class="text-sm font-semibold text-base-content/80 mb-1">评分规则</div>
                      <div class="space-y-2">
                        <div
                          v-for="rubric in getRecommendationQuestionState(recommendation)?.question?.gradingRubric || []"
                          :key="`${recommendation.id}-rubric-${rubric.point}`"
                          class="flex items-start justify-between gap-3 rounded border border-base-300 bg-base-100/80 px-3 py-2 text-sm"
                        >
                          <span class="text-base-content/75">{{ rubric.point }}</span>
                          <span class="font-semibold text-info whitespace-nowrap">{{ rubric.score }} 分</span>
                        </div>
                      </div>
                    </div>
                    <div
                      v-if="typeof getRecommendationQuestionState(recommendation)?.question?.qualityScore === 'number' || getRecommendationQuestionState(recommendation)?.question?.qualitySummary"
                      class="rounded border border-base-300 bg-base-100/80 px-3 py-2"
                    >
                      <div class="text-sm font-semibold text-base-content/80 mb-1">
                        质量评分
                        <span v-if="typeof getRecommendationQuestionState(recommendation)?.question?.qualityScore === 'number'" class="text-info">
                          {{ getRecommendationQuestionState(recommendation)?.question?.qualityScore }}/100
                        </span>
                      </div>
                      <div v-if="getRecommendationQuestionState(recommendation)?.question?.qualitySummary" class="text-sm text-base-content/75 whitespace-pre-wrap">
                        {{ getRecommendationQuestionState(recommendation)?.question?.qualitySummary }}
                      </div>
                    </div>
                    <div v-if="getRecommendationQuestionState(recommendation)?.question?.qualityFlags?.length" class="flex flex-wrap gap-2">
                      <span
                        v-for="flag in getRecommendationQuestionState(recommendation)?.question?.qualityFlags || []"
                        :key="`${recommendation.id}-quality-flag-${flag}`"
                        class="badge badge-warning badge-outline"
                      >
                        {{ flag }}
                      </span>
                    </div>
                  </template>
                  <div v-else class="text-sm text-base-content/60">暂无教学分析</div>
                </div>

                <div
                  v-if="getRecommendationQuestionState(recommendation)?.answerVisible"
                  class="rounded-box border border-base-300 bg-base-200/40 p-4 space-y-3 training-answer"
                >
                  <div>
                    <div class="text-sm font-semibold text-base-content/80 mb-1">标准答案</div>
                    <div class="text-sm text-base-content/75 whitespace-pre-wrap">
                      {{ getRecommendationQuestionState(recommendation)?.question?.standardAnswer }}
                    </div>
                  </div>
                  <div>
                    <div class="text-sm font-semibold text-base-content/80 mb-1">题目解析</div>
                    <div class="text-sm text-base-content/75 whitespace-pre-wrap">
                      {{ getRecommendationQuestionState(recommendation)?.question?.explanation }}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div v-else class="text-sm text-base-content/60 bg-base-200/40 rounded-box p-4">
            {{ pageNotice || EMPTY_RECOMMENDATIONS_MESSAGE }}
          </div>
        </div>
      </div>

      <div class="card bg-base-100 shadow-xl mt-6 relative overflow-hidden border border-secondary/20">
        <div class="card-body relative z-10">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-xl font-semibold flex items-center gap-2">
              <i class="fas fa-book-open text-secondary text-2xl"></i>
              知识点专项训练
            </h2>
          </div>

          <p class="text-sm text-base-content/80 mb-6 leading-relaxed">
            系统会把画像诊断出的薄弱知识点拆成小专题，点开即可进入对应训练；主推荐来源以上方画像推荐任务为准。
          </p>

          <div v-if="aiRecommendedTasks.generatedQuestions.length" class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6 hover:cursor-pointer">
            <div v-for="task in aiRecommendedTasks.generatedQuestions.slice(0, 4)" :key="task.id" class="card bg-base-100 shadow-md border hover:border-secondary transition-all hover:-translate-y-1">
              <figure class="px-4 pt-4 relative">
                <div class="rounded-xl h-32 w-full bg-gradient-to-br from-secondary/20 via-primary/10 to-accent/20 flex items-center justify-center">
                  <i class="fas fa-layer-group text-4xl text-secondary/70"></i>
                </div>
                <div class="absolute top-6 right-6 badge badge-error font-bold shadow-sm">{{ task.type }}</div>
              </figure>
              <div class="card-body p-4 items-center text-center">
                <h2 class="card-title text-base font-bold">{{ task.title }}</h2>
                <p class="text-xs text-base-content/60 mt-1 line-clamp-2">{{ task.reason }}</p>
                <div class="w-full mt-3">
                  <button class="btn btn-secondary btn-sm w-full btn-outline" :disabled="generatingQuestions" @click="startTraining(task.source)">去复习</button>
                </div>
              </div>
            </div>
          </div>
          <div v-else class="text-base-content/60 text-center py-6 bg-base-200/40 rounded-box">
            当前没有可展示的专项训练题目，可先从上方画像推荐任务开始。
          </div>
        </div>
      </div>

      <div class="card bg-base-100 shadow-xl mb-6 mt-8">
        <div class="card-body">
          <h2 class="text-xl font-semibold mb-2">
            <i class="fas fa-list-alt text-primary mr-2"></i>
            解题记录
          </h2>
          <p class="text-sm text-base-content/70 mb-4">
            点击任意记录可查看真实题目、你的答案、正确答案和解析；错题可单独筛选复盘。
          </p>
          <SolveHistoryPanel :records="solveRecords" />
        </div>
      </div>
    </div>

    <div v-else class="space-y-6 animate-[fadeIn_0.5s_ease-out]">
      <div class="card bg-base-100 shadow-xl border-t-4 border-t-primary">
        <div class="card-body flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 class="text-2xl font-bold flex items-center gap-2">
              <i class="fas fa-laptop-code text-primary"></i>
              强化专项训练
            </h2>
            <p class="text-sm text-base-content/60 mt-1">
              逐题作答提交后，系统会重新分析你的表现，并同步更新画像与下一轮推荐。
            </p>
            <div class="mt-2 flex flex-wrap gap-2 text-xs text-base-content/50">
              <span v-if="activeTrainingSessionId" class="badge badge-outline">训练编号 {{ activeTrainingSessionId }}</span>
            </div>
          </div>
          <button class="btn btn-outline btn-sm gap-2" @click="exitTraining">
            <i class="fas fa-sign-out-alt"></i> 返回画像页
          </button>
        </div>
      </div>

      <div v-if="refreshingProfileAfterSubmit" class="alert alert-info py-3">
        <i class="fas fa-spinner fa-spin"></i>
        <span>训练结果已提交，正在刷新画像与下一轮诊断...</span>
      </div>
      <div v-if="profileRefreshError" class="alert alert-warning py-3">
        <i class="fas fa-triangle-exclamation"></i>
        <span>{{ profileRefreshError }}</span>
      </div>

      <div v-if="trainingQuestions.length" class="space-y-6">
        <div v-for="(question, index) in trainingQuestions" :key="question.question_id" class="card bg-base-100 shadow-md">
          <div class="card-body">
            <div class="flex items-start justify-between gap-4 flex-wrap">
              <div class="space-y-2">
                <div class="flex items-center gap-2 flex-wrap">
                  <span class="badge badge-primary badge-outline">第 {{ index + 1 }} 题</span>
                  <span class="badge badge-ghost">{{ questionTypeLabel(question.question_type) }}</span>
                  <span v-if="question.difficulty" class="badge" :class="difficultyBadgeClass(question.difficulty)">
                    {{ difficultyLabel(question.difficulty) }}
                  </span>
                  <span v-if="question.knowledge_point_id" class="badge badge-outline">知识点 {{ question.knowledge_point_id }}</span>
                  <span v-if="question.module_id" class="badge badge-outline">模块 {{ question.module_id }}</span>
                  <span v-if="question.task_id" class="badge badge-outline">任务 {{ question.task_id }}</span>
                </div>
                <h3 class="text-lg font-semibold">{{ question.title }}</h3>
              </div>
              <div class="text-sm text-base-content/50">建议分值：10 分</div>
            </div>

            <p class="mt-4 text-base-content/85 leading-7 whitespace-pre-wrap">{{ question.stem }}</p>

            <div v-if="question.question_type === 'single_choice'" class="mt-4 space-y-2">
              <label
                v-for="(option, optionIndex) in question.options"
                :key="`${question.question_id}-${optionIndex}`"
                class="flex items-center gap-3 p-3 rounded-lg border cursor-pointer transition-colors"
                :class="question.currentAnswer === getSingleChoiceValue(option, optionIndex) ? 'border-primary bg-primary/5' : 'border-base-200 hover:bg-base-200/50'"
              >
                <input
                  v-model="question.currentAnswer"
                  type="radio"
                  class="radio radio-primary radio-sm"
                  :name="`question-${question.question_id}`"
                  :value="getSingleChoiceValue(option, optionIndex)"
                  :disabled="question.submitted"
                />
                <span class="text-base-content">{{ option }}</span>
              </label>
            </div>

            <div v-else-if="question.question_type === 'fill_blank'" class="mt-4">
              <input
                v-model="question.currentAnswer"
                type="text"
                class="input input-bordered w-full text-base"
                placeholder="请输入你的答案"
                :disabled="question.submitted"
              />
            </div>

            <div v-else class="mt-4">
              <textarea
                v-model="question.currentAnswer"
                class="textarea textarea-bordered w-full h-32 text-base"
                placeholder="请输入你的作答内容"
                :disabled="question.submitted"
              ></textarea>
            </div>

            <div class="mt-6 flex flex-col gap-3">
              <div class="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-3">
                <div class="flex-1">
                  <div v-if="question.submitError" class="text-sm text-error">
                    {{ question.submitError }}
                  </div>
                  <div v-if="question.submitted" class="p-3 rounded-lg border" :class="{
                    'bg-success/10 text-success border-success/20': question.isCorrect === true,
                    'bg-error/10 text-error border-error/20': question.isCorrect === false,
                    'bg-info/10 text-info border-info/20': question.isCorrect === null
                  }">
                    <div class="font-bold mb-1 flex items-center gap-2">
                      <i
                        class="fas"
                        :class="question.isCorrect === true ? 'fa-check-circle' : question.isCorrect === false ? 'fa-times-circle' : 'fa-circle-info'"
                      ></i>
                      <span>
                        {{
                          question.isCorrect === true
                            ? '回答正确'
                            : question.isCorrect === false
                              ? '回答有误'
                              : '已提交，等待参考答案对照'
                        }}
                      </span>
                    </div>
                    <div class="text-sm">
                      本题得分：{{ question.score ?? 0 }} 分
                      <span v-if="question.costTime !== null" class="ml-2">耗时：{{ question.costTime }} 秒</span>
                    </div>
                  </div>
                </div>

                <div class="flex flex-wrap gap-2">
                  <button
                    v-if="hasExplanationContent(question)"
                    class="btn btn-ghost btn-sm"
                    :disabled="!question.submitted"
                    @click="toggleExplanation(question)"
                  >
                    <i class="fas fa-book-open"></i>
                    {{ question.explanationVisible ? '收起解析' : '查看解析' }}
                  </button>
                  <button
                    class="btn btn-primary min-w-[120px]"
                    :disabled="question.submitting || question.submitted"
                    @click="submitQuestion(question)"
                  >
                    <i class="fas" :class="question.submitting ? 'fa-spinner fa-spin' : 'fa-paper-plane'"></i>
                    {{ question.submitting ? '提交中...' : question.submitted ? '已提交' : '提交答案' }}
                  </button>
                </div>
              </div>

              <div v-if="question.submitted && question.explanationVisible && hasExplanationContent(question)" class="rounded-box border border-base-300 bg-base-200/40 p-4 space-y-3 training-answer">
                <div v-if="question.explanation">
                  <div class="text-sm font-semibold text-base-content/80 mb-1">题目解析</div>
                  <div class="text-sm text-base-content/75 whitespace-pre-wrap">{{ question.explanation }}</div>
                </div>
                <div v-if="question.standard_answer">
                  <div class="text-sm font-semibold text-base-content/80 mb-1">标准答案</div>
                  <div class="text-sm text-base-content/75 whitespace-pre-wrap">{{ question.standard_answer }}</div>
                </div>
                <div v-if="question.reference_answer">
                  <div class="text-sm font-semibold text-base-content/80 mb-1">参考答案</div>
                  <div class="text-sm text-base-content/75 whitespace-pre-wrap">{{ question.reference_answer }}</div>
                </div>
                <div v-if="question.scoring_rubric.length">
                  <div class="text-sm font-semibold text-base-content/80 mb-1">评分要点</div>
                  <ul class="list-disc pl-5 text-sm text-base-content/75 space-y-1">
                    <li v-for="(rubric, rubricIndex) in question.scoring_rubric" :key="`${question.question_id}-rubric-${rubricIndex}`">
                      {{ rubric }}
                    </li>
                  </ul>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div v-else class="card bg-base-100 shadow-md">
        <div class="card-body">
          <div class="text-base-content/60">当前训练会话还没有题目，请返回画像页重新生成。</div>
        </div>
      </div>
    </div>

    <dialog class="modal" :class="{ 'modal-open': showProfileModal }">
      <div class="modal-box w-11/12 max-w-4xl bg-base-100/95 backdrop-blur-sm">
        <h3 class="font-bold text-2xl mb-6 flex items-center gap-3">
          <i class="fas fa-user-edit text-primary"></i>
          个人基本信息
        </h3>

        <!-- 头像上传区域 -->
        <div class="flex items-center gap-6 mb-8 pb-6 border-b border-base-300">
          <div class="relative group">
            <div class="w-24 h-24 rounded-full ring-4 ring-primary/30 shadow-lg bg-base-200 flex items-center justify-center overflow-hidden">
              <img
                v-if="modalAvatarSrc"
                :src="modalAvatarSrc"
                alt="头像预览"
                class="w-full h-full object-cover"
              />
              <i v-else class="fas fa-user text-4xl text-base-content/30"></i>
            </div>
          </div>
          <div class="flex-1">
            <label class="label">
              <span class="label-text font-medium">头像</span>
            </label>
            <div class="flex items-center gap-3">
              <label
                v-if="isEditing"
                class="btn btn-sm btn-outline gap-2 cursor-pointer"
                :class="{ 'btn-disabled': isUploadingAvatar }"
              >
                <span v-if="isUploadingAvatar" class="loading loading-spinner loading-xs"></span>
                <i v-else class="fas fa-upload"></i>
                <span>{{ isUploadingAvatar ? '上传中...' : '选择图片' }}</span>
                <input
                  type="file"
                  accept="image/png,image/jpeg,image/jpg,image/gif,image/webp"
                  class="hidden"
                  @change="onAvatarChange"
                  :disabled="isUploadingAvatar"
                />
              </label>
              <button
                v-if="isEditing && avatarFile"
                class="btn btn-ghost btn-sm"
                @click="avatarFile = null; avatarPreviewUrl = ''"
              >
                <i class="fas fa-times"></i>
                取消
              </button>
            </div>
            <div v-if="avatarError" class="alert alert-error mt-2 py-2 text-sm">
              <i class="fas fa-exclamation-circle"></i>
              <span>{{ avatarError }}</span>
            </div>
            <p v-else-if="isEditing" class="text-xs text-base-content/60 mt-1">
              支持 PNG/JPG/GIF/WebP，最大 5MB
            </p>
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-6">
          <div
            v-for="field in [
              { key: 'userName' as keyof User, label: '姓名', icon: 'fa-user', type: 'text' },
              { key: 'userStudentNumber' as keyof User, label: '学号', icon: 'fa-id-card', type: 'text', readonly: true },
              { key: 'userTel' as keyof User, label: '电话', icon: 'fa-phone', type: 'tel' },
              { key: 'userEmail' as keyof User, label: '邮箱', icon: 'fa-envelope', type: 'email' },
              { key: 'userAcademy' as keyof User, label: '学院', icon: 'fa-university', type: 'text' },
              { key: 'userClass' as keyof User, label: '班级', icon: 'fa-users', type: 'text' }
            ]"
            :key="field.key"
            class="form-control"
          >
            <label class="label">
              <span class="label-text flex items-center gap-2">
                <i :class="['fas', field.icon, 'text-primary']"></i>
                {{ field.label }}
              </span>
            </label>
            <input
              v-model="editedUser[field.key]"
              :type="field.type"
              class="input input-bordered bg-base-200/50 focus:bg-base-100 transition-colors shadow-sm"
              :readonly="!isEditing || field.readonly"
              :class="{ 'input-disabled bg-base-200 opacity-60': !isEditing || field.readonly }"
            />
          </div>

          <div class="form-control">
            <label class="label">
              <span class="label-text flex items-center gap-2">
                <i class="fas fa-venus-mars text-primary"></i>
                性别
              </span>
            </label>
            <select
              v-model="editedUser.userGender"
              class="select select-bordered h-12 bg-base-200/50 shadow-sm text-left py-0 leading-normal"
              :disabled="!isEditing"
              :class="{ 'select-disabled bg-base-200 opacity-60': !isEditing }"
            >
              <option :value="1">男</option>
              <option :value="0">女</option>
            </select>
          </div>
        </div>

        <div class="modal-action mt-8 flex justify-end gap-3">
          <button v-if="!isEditing" class="btn btn-primary gap-2" @click="startEdit">
            <i class="fas fa-edit"></i>
            编辑资料
          </button>
          <div v-else class="flex gap-2">
            <button class="btn btn-primary" :disabled="isLoading" @click="saveEdit">
              <i class="fas" :class="isLoading ? 'fa-spinner fa-spin' : 'fa-save'"></i>
              <span>{{ isLoading ? '保存中...' : '保存' }}</span>
            </button>
            <button class="btn btn-ghost" @click="cancelEdit">取消编辑</button>
          </div>
          <button class="btn btn-outline" @click="closeProfileModal">关闭</button>
        </div>
      </div>
      <form method="dialog" class="modal-backdrop" @click="closeProfileModal">
        <button>close</button>
      </form>
    </dialog>
  </div>
</template>

<style scoped>
.container-fluid {
  width: 100%;
  max-width: 100%;
  margin: 0 auto;
}

html,
body {
  overflow-x: hidden;
  margin: 0;
  padding: 0;
  width: 100%;
}

.input,
.select,
.textarea {
  transition: all 0.3s ease;
}

.input:focus,
.select:focus,
.textarea:focus {
  transform: translateY(-1px);
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
}

.stat {
  transition: all 0.3s ease;
}

.stat:hover {
  transform: translateY(-2px);
}

.stat-figure {
  transition: transform 0.3s ease;
}

.stat:hover .stat-figure {
  transform: scale(1.1);
}

.avatar img {
  transition: all 0.3s ease;
}

.avatar:hover img {
  transform: scale(1.05);
}

.form-control .input,
.form-control .select {
  font-size: 1.05rem;
  padding: 0.75rem 1rem;
}

.label-text {
  font-weight: 500;
  font-size: 0.95rem;
}

.form-control i {
  font-size: 1.2rem;
}

.training-answer {
  overflow-wrap: anywhere;
}
</style>

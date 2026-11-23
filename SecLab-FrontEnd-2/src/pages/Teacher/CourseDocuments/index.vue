<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import {
  deleteRagDocument,
  getApiErrorMessage,
  getRagConfig,
  getTeacherCourseList,
  listRagDocuments,
  reloadRagConfig,
  testRagEmbedding,
  uploadRagDocument,
  type RagConfigDto,
  type RagDocumentDto,
  type AdminCourse,
} from '../../../api'
import '../teacher-page.css'

const courses = ref<AdminCourse[]>([])
const selectedCourseId = ref<number | null>(null)
const documents = ref<RagDocumentDto[]>([])
const ragConfig = ref<RagConfigDto | null>(null)
const loading = ref(false)
const uploading = ref(false)
const reloading = ref(false)
const testing = ref(false)
const testResult = ref('')
const error = ref('')
const notice = ref('')
const fileInput = ref<HTMLInputElement | null>(null)
const dragOver = ref(false)

const selectedCourse = computed(() =>
  courses.value.find((c) => c.id === selectedCourseId.value) || null
)
const canUpload = computed(() => Boolean(ragConfig.value?.embeddingConfigured))

const loadCourses = async () => {
  try {
    courses.value = await getTeacherCourseList()
    if (!selectedCourseId.value && courses.value.length) {
      selectedCourseId.value = courses.value[0].id
    }
  } catch (err: unknown) {
    error.value = getApiErrorMessage(err, '课程列表加载失败。')
  }
}

const loadDocuments = async () => {
  if (!selectedCourseId.value) return
  loading.value = true
  error.value = ''
  try {
    documents.value = await listRagDocuments(selectedCourseId.value)
  } catch (err: unknown) {
    error.value = getApiErrorMessage(err, '课程资料加载失败。')
  } finally {
    loading.value = false
  }
}

const loadConfig = async () => {
  try {
    ragConfig.value = await getRagConfig()
  } catch (err: unknown) {
    error.value = getApiErrorMessage(err, 'RAG 配置读取失败。')
  }
}

/** 改完 .env 不用重启服务，点一下就能重新读取 */
const reloadConfig = async () => {
  reloading.value = true
  testResult.value = ''
  try {
    ragConfig.value = await reloadRagConfig()
    notice.value = ragConfig.value.embeddingConfigured
      ? '配置已重新加载，向量模型就绪。'
      : '已重新加载，但仍未读到 EMBEDDING_API_KEY，请确认写到了 ai-agent-service/.env。'
  } catch (err: unknown) {
    error.value = getApiErrorMessage(err, '配置重载失败。')
  } finally {
    reloading.value = false
  }
}

/** 真实打一次向量接口，确认 Key 有效 */
const runTest = async () => {
  testing.value = true
  testResult.value = ''
  try {
    const result = await testRagEmbedding()
    testResult.value = `连接正常 · ${result.dimensions} 维 · ${result.latencyMs}ms${result.note ? ` · ${result.note}` : ''}`
  } catch (err: unknown) {
    testResult.value = ''
    error.value = getApiErrorMessage(err, '向量模型连接失败。')
  } finally {
    testing.value = false
  }
}

const onZoneClick = () => {
  if (!canUpload.value) {
    notice.value = '尚未配置 EMBEDDING_API_KEY：请先在 ai-agent-service/.env 中填写硅基流动 API Key，再点「重新加载配置」。'
    return
  }
  fileInput.value?.click()
}

const handleFile = async (file: File | undefined) => {
  if (!file || !selectedCourseId.value) return
  if (!canUpload.value) {
    notice.value = '尚未配置 EMBEDDING_API_KEY，请先在后端 .env 中填写硅基流动 API Key。'
    return
  }
  uploading.value = true
  error.value = ''
  notice.value = `正在导入「${file.name}」，向量化可能需要十几秒…`
  try {
    const result: any = await uploadRagDocument(selectedCourseId.value, file)
    notice.value = `导入成功：${result.chunkCount || 0} 个文本块已加入 ${selectedCourse?.value?.name || '本课程'} 的知识库。`
    await loadDocuments()
  } catch (err: unknown) {
    error.value = getApiErrorMessage(err, '文档导入失败。')
    notice.value = ''
  } finally {
    uploading.value = false
    if (fileInput.value) fileInput.value.value = ''
  }
}

const onFileChange = (e: Event) => {
  const target = e.target as HTMLInputElement
  void handleFile(target.files?.[0])
}

const onDrop = (e: DragEvent) => {
  dragOver.value = false
  void handleFile(e.dataTransfer?.files?.[0])
}

const removeDocument = async (doc: RagDocumentDto) => {
  if (!window.confirm(`确定删除「${doc.fileName}」及其所有向量块吗？`)) return
  try {
    await deleteRagDocument(doc.sourceId, doc.courseId)
    notice.value = `已删除「${doc.fileName}」`
    await loadDocuments()
  } catch (err: unknown) {
    error.value = getApiErrorMessage(err, '删除失败。')
  }
}

const formatSize = (size: number) =>
  size > 1024 * 1024 ? `${(size / 1024 / 1024).toFixed(1)} MB` : `${Math.ceil(size / 1024)} KB`

const formatTime = (value?: string | null) =>
  value ? new Date(value).toLocaleString('zh-CN', { hour12: false }) : '—'

watch(selectedCourseId, () => { notice.value = ''; void loadDocuments() })

onMounted(async () => {
  await Promise.all([loadCourses(), loadConfig()])
  await loadDocuments()
})
</script>

<template>
  <div class="teacher-page">
    <header class="page-head">
      <div>
        <h1>课程资料 · 知识库</h1>
        <p>上传课程资料后自动切块并向量化，学生在对应课程的 AI 助手提问时会参考这些资料回答。</p>
      </div>
    </header>

    <div v-if="error" class="notice error">{{ error }}</div>
    <div v-if="notice" class="notice info">{{ notice }}</div>

    <div class="rag-status">
      <span class="status-dot" :class="ragConfig?.embeddingConfigured ? 'on' : 'off'"></span>
      <span v-if="!ragConfig">正在检查 RAG 配置…</span>
      <span v-else-if="ragConfig.embeddingConfigured">
        向量模型已就绪：<strong>{{ ragConfig.model }}</strong>
        <span class="muted"> · 分块 {{ ragConfig.chunkSize }} 字 · 检索 Top {{ ragConfig.topK }}</span>
      </span>
      <span v-else class="warn-text">
        向量模型未配置：请在 ai-agent-service/.env 填写 EMBEDDING_API_KEY（硅基流动），保存后点右侧「重新加载配置」
      </span>
      <span class="spacer"></span>
      <span v-if="testResult" class="test-result">{{ testResult }}</span>
      <button type="button" class="status-btn" :disabled="reloading" @click="reloadConfig">
        {{ reloading ? '重载中…' : '重新加载配置' }}
      </button>
      <button
        v-if="ragConfig?.embeddingConfigured"
        type="button"
        class="status-btn primary"
        :disabled="testing"
        @click="runTest"
      >{{ testing ? '测试中…' : '测试连接' }}</button>
    </div>

    <div class="panel">
      <div class="panel-head">
        <div>
          <h2>选择课程</h2>
          <p>资料将归属到所选课程，只在该课程的对话中生效</p>
        </div>
      </div>
      <div class="course-chips">
        <button
          v-for="course in courses"
          :key="course.id"
          type="button"
          class="chip"
          :class="{ active: selectedCourseId === course.id }"
          @click="selectedCourseId = course.id"
        >{{ course.name }}</button>
      </div>
    </div>

    <div class="panel">
      <div class="panel-head">
        <div>
          <h2>上传资料</h2>
          <p>支持 .txt / .md / .pdf / .docx，单个文件不超过 20MB</p>
        </div>
      </div>
      <div
        class="drop-zone"
        :class="{ over: dragOver, disabled: !canUpload || uploading }"
        @dragover.prevent="dragOver = true"
        @dragleave.prevent="dragOver = false"
        @drop.prevent="onDrop"
        @click="onZoneClick"
      >
        <input
          ref="fileInput"
          type="file"
          accept=".txt,.md,.markdown,.pdf,.docx,.doc,.csv"
          hidden
          @change="onFileChange"
        />
        <div class="drop-icon">＋</div>
        <div class="drop-title">{{ uploading ? '正在导入并向量化…' : '点击选择文件，或拖拽到此处' }}</div>
        <div class="drop-sub">导入后会自动切块、调用向量模型并存入知识库</div>
      </div>
    </div>

    <div class="panel">
      <div class="panel-head">
        <div>
          <h2>{{ selectedCourse?.name || '课程' }}的资料列表</h2>
          <p>共 {{ documents.length }} 份资料</p>
        </div>
      </div>
      <div v-if="loading" class="empty">加载中…</div>
      <div v-else-if="!documents.length" class="empty">还没有上传资料。上传后，学生在这门课的 AI 助手就能基于资料回答。</div>
      <table v-else class="doc-table">
        <thead>
          <tr><th>文件名</th><th>类型</th><th>大小</th><th>文本块</th><th>状态</th><th>上传时间</th><th></th></tr>
        </thead>
        <tbody>
          <tr v-for="doc in documents" :key="doc.sourceId">
            <td class="file-name">{{ doc.fileName }}</td>
            <td>{{ doc.fileType.toUpperCase() }}</td>
            <td>{{ formatSize(doc.fileSize) }}</td>
            <td>{{ doc.chunkCount }}</td>
            <td>
              <span class="badge" :class="doc.status">
                {{ doc.status === 'ready' ? '已就绪' : doc.status === 'failed' ? '失败' : '处理中' }}
              </span>
            </td>
            <td>{{ formatTime(doc.createdAt) }}</td>
            <td>
              <button type="button" class="secondary-button danger" @click="removeDocument(doc)">删除</button>
            </td>
          </tr>
        </tbody>
      </table>
      <div v-for="doc in documents.filter(d => d.status === 'failed')" :key="doc.sourceId + '-err'" class="notice error small">
        {{ doc.fileName }}：{{ doc.errorMessage }}
      </div>
    </div>
  </div>
</template>

<style scoped>
.rag-status { display: flex; align-items: center; gap: 8px; padding: 12px 16px; margin-bottom: 16px; border-radius: 8px; background: #f4f7fb; font-size: 13px; color: #56647a; }
.rag-status .spacer { flex: 1; }
.status-btn { border: 1px solid #d5deeb; background: #fff; color: #56647a; border-radius: 6px; padding: 5px 11px; font-size: 12px; cursor: pointer; white-space: nowrap; }
.status-btn:hover:not(:disabled) { border-color: #1e5fbf; color: #1e5fbf; }
.status-btn:disabled { opacity: .55; cursor: not-allowed; }
.status-btn.primary { background: #1e5fbf; border-color: #1e5fbf; color: #fff; }
.status-btn.primary:hover:not(:disabled) { background: #1a53a8; color: #fff; }
.test-result { color: #22a06b; font-size: 12px; white-space: nowrap; }
.status-dot { width: 8px; height: 8px; border-radius: 50%; }
.status-dot.on { background: #22a06b; }
.status-dot.off { background: #e0a126; }
.muted { color: #98a3b3; }
.warn-text { color: #b5730a; }
.course-chips { display: flex; flex-wrap: wrap; gap: 8px; padding: 16px; }
.chip { border: 1px solid #dce3ed; background: #fff; border-radius: 18px; padding: 7px 14px; font-size: 13px; cursor: pointer; color: #56647a; }
.chip:hover { border-color: #1e5fbf; color: #1e5fbf; }
.chip.active { background: #1e5fbf; border-color: #1e5fbf; color: #fff; }
.drop-zone { margin: 16px; border: 2px dashed #c9d5e6; border-radius: 10px; padding: 34px 20px; text-align: center; cursor: pointer; transition: .15s; }
.drop-zone:hover, .drop-zone.over { border-color: #1e5fbf; background: #f4f9ff; }
.drop-zone.disabled { opacity: .55; cursor: not-allowed; }
.drop-icon { font-size: 34px; color: #1e5fbf; line-height: 1; }
.drop-title { margin-top: 10px; font-size: 15px; font-weight: 600; color: #25324a; }
.drop-sub { margin-top: 5px; font-size: 12px; color: #98a3b3; }
.doc-table { width: 100%; border-collapse: collapse; font-size: 13px; }
.doc-table th { text-align: left; padding: 11px 14px; color: #98a3b3; font-weight: 600; border-bottom: 1px solid #e8edf4; }
.doc-table td { padding: 11px 14px; border-bottom: 1px solid #f0f3f8; color: #56647a; }
.file-name { font-weight: 600; color: #25324a; max-width: 260px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.badge { padding: 3px 9px; border-radius: 10px; font-size: 11px; }
.badge.ready { background: #e6f6ef; color: #22a06b; }
.badge.failed { background: #fdecec; color: #cf4040; }
.badge.processing { background: #fdf4e3; color: #b5730a; }
.empty { padding: 28px 16px; text-align: center; color: #98a3b3; font-size: 13px; }
.notice.small { margin: 8px 16px 16px; font-size: 12px; }
.secondary-button.danger { color: #cf4040; border-color: #f0c9c9; }
</style>

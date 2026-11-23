<script setup lang="ts">
import { computed, onMounted, ref, type Ref } from 'vue'
import CourseOverView from './components/CourseOverView.vue'
import type { CourseOverViewType } from './components/CourseOverView'
import { getCourseList as fetchCourseList, image, type CourseSummaryDto } from '../../../api'
import { mergeCourseSummariesWithPresentation } from '../../../mock/catalogPresentation'

function mapStatus(status: string | null | undefined): 'in-progress' | 'completed' | 'available' | 'hidden' {
  if (!status) return 'available'

  switch (status.toLowerCase()) {
    case 'draft':
    case 'locked':
    case 'archived':
      return 'hidden'
    case 'in_progress':
    case 'in-progress':
      return 'in-progress'
    case 'completed':
      return 'completed'
    default:
      return 'available'
  }
}

function mapDifficulty(difficulty: number | null | undefined): 1 | 2 | 3 | 4 | 5 {
  if (!difficulty) return 3
  return Math.min(Math.max(difficulty, 1), 5) as 1 | 2 | 3 | 4 | 5
}

// 本地放在 public/ai 下的封面直接按根路径访问，其余交给 image() 处理
function resolveCover(imageUrl: string | null | undefined): string {
  if (!imageUrl) return '/default-course-image.png'
  if (imageUrl.includes('/')) return `/${imageUrl.replace(/^\//, '')}`
  return image(imageUrl)
}

function mapApiDataToViewData(apiData: CourseSummaryDto[]): CourseOverViewType[] {
  return apiData
    .map((course) => {
      const status = mapStatus(course.status)
      if (status === 'hidden') {
        return null
      }

      return {
        id: course.id,
        name: course.name,
        image: resolveCover(course.imageUrl),
        description: course.description || '',
        status,
        category: course.type || 'ai-basic',
        difficulty: mapDifficulty(course.difficulty),
        estimatedHours: course.estimatedHours ?? 2,
        tags: course.tags || [],
      }
    })
    .filter((course): course is CourseOverViewType => Boolean(course))
}

async function getCourseList(): Promise<CourseOverViewType[]> {
  const response = await fetchCourseList()
  if (response.message !== 'success') {
    throw new Error(response.message || '获取课程列表失败')
  }

  return mapApiDataToViewData(mergeCourseSummariesWithPresentation(response.data || []))
}

const isLoaded = ref(false)
const isLoading = ref(true)
const pageError = ref('')
const searchQuery = ref('')
const selectedCategory = ref('')

const categories = [
  { id: 'ai-basic', name: 'AI基础', icon: 'fa-robot' },
  { id: 'ai-perception', name: '感知智能', icon: 'fa-eye' },
  { id: 'ai-cognition', name: '认知与决策', icon: 'fa-brain' },
  { id: 'ai-embodied', name: '具身智能', icon: 'fa-cubes' },
  { id: 'ai-creative', name: '智能创作', icon: 'fa-music' },
]

const courses: Ref<CourseOverViewType[]> = ref([])

const stats = computed(() => ({
  total: courses.value.length,
  inProgress: courses.value.filter((c) => c.status === 'in-progress').length,
  completed: courses.value.filter((c) => c.status === 'completed').length,
  available: courses.value.filter((c) => c.status === 'available').length,
}))

const filteredCourses = computed(() => {
  return courses.value.filter((course) => {
    if (searchQuery.value && !course.name.toLowerCase().includes(searchQuery.value.toLowerCase())) {
      return false
    }
    if (selectedCategory.value && course.category !== selectedCategory.value) {
      return false
    }
    return true
  })
})

onMounted(async () => {
  try {
    courses.value = await getCourseList()
  } catch (error) {
    console.error('Failed to initialize courses:', error)
    courses.value = []
    pageError.value = '课程列表加载失败，请稍后重试。'
    courses.value = mapApiDataToViewData(mergeCourseSummariesWithPresentation())
    pageError.value = ''
  } finally {
    isLoading.value = false
    setTimeout(() => {
      isLoaded.value = true
    }, 100)
  }
})
</script>

<template>
  <div class="container-fluid px-4 py-4 overflow-x-hidden min-h-screen">
    <div class="text-center mb-6" :class="{ 'animate-fade-in': isLoaded }">
      <h1 class="text-3xl font-bold mb-1 bg-clip-text text-transparent bg-gradient-to-r from-primary via-secondary to-accent">AI 微课十讲</h1>
      <p class="text-sm text-base-content/70">立心 LMS · 中学生人工智能微课，十节课带你走进 AI 世界</p>
    </div>

    <div class="stats shadow w-full mb-6 bg-base-100 backdrop-blur-sm" :class="{ 'animate-slide-up': isLoaded }">
      <div class="stat py-2">
        <div class="stat-figure text-primary">
          <i class="fas fa-book-open text-xl"></i>
        </div>
        <div class="stat-title text-xs">总课程</div>
        <div class="stat-value text-primary text-xl">{{ stats.total }}</div>
      </div>

      <div class="stat py-2">
        <div class="stat-figure text-info">
          <i class="fas fa-spinner text-xl"></i>
        </div>
        <div class="stat-title text-xs">进行中</div>
        <div class="stat-value text-info text-xl">{{ stats.inProgress }}</div>
      </div>

      <div class="stat py-2">
        <div class="stat-figure text-success">
          <i class="fas fa-check-circle text-xl"></i>
        </div>
        <div class="stat-title text-xs">已完成</div>
        <div class="stat-value text-success text-xl">{{ stats.completed }}</div>
      </div>

      <div class="stat py-2">
        <div class="stat-figure text-warning">
          <i class="fas fa-lock-open text-xl"></i>
        </div>
        <div class="stat-title text-xs">可开始</div>
        <div class="stat-value text-warning text-xl">{{ stats.available }}</div>
      </div>
    </div>

    <div v-if="pageError" class="alert alert-error mb-6">
      <span>{{ pageError }}</span>
    </div>

    <div class="flex flex-col md:flex-row gap-3 mb-6" :class="{ 'animate-slide-up': isLoaded }" style="animation-delay: 0.2s">
      <div class="flex-1 relative">
        <input type="text" placeholder="搜索课程..." class="input input-sm input-bordered w-full pl-8 pr-3 bg-base-100/70 focus:bg-base-100 transition-all duration-300 shadow-sm hover:shadow focus:shadow-md" v-model="searchQuery" />
        <i class="fas fa-search absolute left-3 top-1/2 -translate-y-1/2 text-xs text-base-content/50"></i>
      </div>

      <div class="flex gap-1">
        <button v-for="category in categories" :key="category.id" class="btn btn-ghost btn-sm gap-1 text-xs" :class="{ 'btn-active': selectedCategory === category.id }" @click="selectedCategory = selectedCategory === category.id ? '' : category.id">
          <i :class="['fas', category.icon]"></i>
          <span>{{ category.name }}</span>
        </button>
      </div>
    </div>

    <div v-if="isLoading" class="flex justify-center py-10">
      <span class="loading loading-spinner loading-lg text-primary"></span>
    </div>
    <div v-else-if="!courses.length" class="card bg-base-100 shadow-xl">
      <div class="card-body text-center py-10 text-base-content/60">
        暂无课程
      </div>
    </div>
    <div v-else class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4" :class="{ 'animate-fade-in': isLoaded }" style="animation-delay: 0.3s">
      <template v-if="filteredCourses.length">
        <div v-for="(course, index) in filteredCourses" :key="course.id" :style="{ animationDelay: `${index * 0.05}s` }" class="animate-slide-up">
          <CourseOverView :course="course" />
        </div>
      </template>
      <div v-else class="col-span-full text-center py-6">
        <div class="text-4xl mb-2 text-base-content/30">
          <i class="fas fa-search"></i>
        </div>
        <h3 class="text-lg font-semibold mb-1">未找到匹配的课程</h3>
        <p class="text-sm text-base-content/70">试试调整搜索条件</p>
      </div>
    </div>
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

.animate-fade-in {
  animation: fadeIn 0.8s ease-out forwards;
}

.animate-slide-up {
  opacity: 0;
  animation: slideUp 0.5s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
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

.input {
  transition: all 0.3s ease;
}

.input:focus {
  outline: none;
  border-color: var(--color-primary);
}

.btn-ghost {
  transition: all 0.3s ease;
}
</style>

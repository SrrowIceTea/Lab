<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import type { ModuleOverViewType } from './components/ModuleOverView.ts'
import ModuleOverView from './components/ModuleOverView.vue'

const router = useRouter()

// 修改模块数据，添加分数计算
const calculateScore = (difficulty: number, time: string): number => {
  // 解析预计用时，提取小时数
  const hours = parseFloat(time.split('-')[1]?.split('小时')[0] || time.split('小时')[0])
  // 计算总分：难度基础分 + 时间加成，上限100分
  const score = Math.min(difficulty * 15 + hours * 5, 100)
  return Math.round(score)
}

// 模拟模块数据
const modules = ref<ModuleOverViewType[]>([
  {
    id: 1,
    name: 'AI 应用大搜索',
    description: '在身边找出 5 个 AI 应用场景，分析它们分别解决了什么问题。',
    difficulty: 1,
    type: '人工智能基础',
    status: 'available',
    estimatedTime: '1小时',
    score: calculateScore(1, '1小时')
  },
  {
    id: 2,
    name: '图像识别初体验',
    description: '用在线图像分类模型测试 10 张图片，记录识别结果并分析错误原因。',
    difficulty: 2,
    type: '感知智能',
    status: 'available',
    estimatedTime: '1-2小时',
    score: calculateScore(2, '1-2小时')
  },
  {
    id: 3,
    name: '让机器给句子分类',
    description: '用情感分析工具处理影评文本，观察分词与词向量对结果的影响。',
    difficulty: 2,
    type: '感知智能',
    status: 'available',
    estimatedTime: '1-2小时',
    score: calculateScore(2, '1-2小时')
  },
  {
    id: 4,
    name: '搭一个知识图谱',
    description: '为校园场景构建小型知识图谱，设计实体、关系与推理规则。',
    difficulty: 3,
    type: '认知与决策',
    status: 'available',
    estimatedTime: '1-2小时',
    score: calculateScore(3, '1-2小时')
  },
  {
    id: 5,
    name: '训练第一个分类器',
    description: '用可视化平台训练鸢尾花分类模型，调参观察准确率的变化。',
    difficulty: 3,
    type: '认知与决策',
    status: 'available',
    estimatedTime: '1-2小时',
    score: calculateScore(3, '1-2小时')
  },
  {
    id: 6,
    name: '设计一台服务机器人',
    description: '围绕校园导览场景，画出机器人的感知—决策—执行闭环流程。',
    difficulty: 2,
    type: '具身智能',
    status: 'available',
    estimatedTime: '1-2小时',
    score: calculateScore(2, '1-2小时')
  },
  {
    id: 7,
    name: '多智能体协作推演',
    description: '在仿真环境中为 3 个智能体设计协作策略，观察群体行为。',
    difficulty: 4,
    type: '具身智能',
    status: 'available',
    estimatedTime: '2小时',
    score: calculateScore(4, '2小时')
  },
  {
    id: 8,
    name: '搭建简易物理仿真',
    description: '用物理引擎模拟小球碰撞，理解仿真环境如何生成训练数据。',
    difficulty: 4,
    type: '具身智能',
    status: 'available',
    estimatedTime: '2小时',
    score: calculateScore(4, '2小时')
  },
  {
    id: 9,
    name: '生成一段 AI 旋律',
    description: '用 AI 作曲工具生成 8 小节旋律，比较不同风格参数的效果。',
    difficulty: 2,
    type: '智能创作',
    status: 'available',
    estimatedTime: '1小时',
    score: calculateScore(2, '1小时')
  },
  {
    id: 10,
    name: '我的 AI 学习计划',
    description: '结合十讲内容，制定一份面向自己的 AI 学习路线图。',
    difficulty: 1,
    type: '人工智能基础',
    status: 'available',
    estimatedTime: '1小时',
    score: calculateScore(1, '1小时')
  }
])



onMounted(()=>{
  // getModuleList().then((res)=>{
  //   modules.value = res.data;
  // })
})

// 开始实践：跳转到对应模块路径
const handleStartExperiment = (moduleId: number) => {
  router.push(`/user/module/${moduleId}`)
}

// 筛选条件
const filters = ref({
  type: '',
  difficulty: '',
  status: ''
})

// 类型列表 
const types = ['人工智能基础', '感知智能', '认知与决策', '具身智能', '智能创作']

// 添加搜索关键词
const searchQuery = ref('')

// 更新筛选逻辑
// 更新筛选逻辑
const filteredModules = computed(() => {
  // 首先进行筛选
  const filtered = modules.value.filter(module => {
    // 搜索过滤
    if (searchQuery.value && !module.name.toLowerCase().includes(searchQuery.value.toLowerCase()) &&
        !module.description.toLowerCase().includes(searchQuery.value.toLowerCase())) {
      return false
    }
    // 现有的筛选条件
    if (filters.value.type && module.type !== filters.value.type) return false
    if (filters.value.status && module.status !== filters.value.status) return false
    if (filters.value.difficulty && module.difficulty !== parseInt(filters.value.difficulty)) return false
    return true
  })

  // 然后按照状态排序
  return filtered.sort((a, b) => {
    const statusOrder = {
      'available': 0,  // 可开始 排第一
      'locked': 1,     // 未解锁 排第二
      'completed': 2   // 可进行 排第三
    }
    return statusOrder[a.status] - statusOrder[b.status]
  })
})

// 重置筛选器
const resetFilters = () => {
  filters.value = {
    type: '',
    difficulty: '',
    status: ''
  }
  searchQuery.value = ''
}

// 获取统计信息
const stats = computed(() => ({
  total: modules.value.length,
  completed: modules.value.filter(m => m.status === 'completed').length,
  available: modules.value.filter(m => m.status === 'available').length,
  locked: modules.value.filter(m => m.status === 'locked').length
}))
</script>

<template>
  <div class="container-fluid px-4 py-6 overflow-x-hidden">
    <!-- 统计信息 -->
    <div class="stats shadow w-full mb-6">
      <div class="stat">
        <div class="stat-figure text-primary">
          <i class="fas fa-cube text-3xl"></i>
        </div>
        <div class="stat-title">实践模块数</div>
        <div class="stat-value text-primary">{{ stats.total }}</div>
      </div>
      
      <div class="stat">
        <div class="stat-figure text-success">
          <i class="fas fa-check-circle text-3xl"></i>
        </div>
        <div class="stat-title">已完成</div>
        <div class="stat-value text-success">{{ stats.completed }}</div>
      </div>
      
      <div class="stat">
        <div class="stat-figure text-warning">
          <i class="fas fa-unlock text-3xl"></i>
        </div>
        <div class="stat-title">可开始</div>
        <div class="stat-value text-warning">{{ stats.available }}</div>
      </div>
      
      <div class="stat">
        <div class="stat-figure text-error">
          <i class="fas fa-lock text-3xl"></i>
        </div>
        <div class="stat-title">未解锁</div>
        <div class="stat-value text-error">{{ stats.locked }}</div>
      </div>
    </div>
    
    <!-- 筛选器 -->
    <div class="card bg-base-100 shadow-xl mb-6 overflow-hidden">
      <!-- 搜索区域 -->

      <div class="card-body pt-4">

        <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
          <!-- 类型筛选 -->
          <div class="form-control">
            <label class="label cursor-pointer gap-2 pb-2">
              <i class="fas fa-tags text-primary"></i>
              <span class="label-text">类型</span>
            </label>
            <select 
              class="select select-bordered w-full bg-base-100/70 hover:bg-base-100 transition-colors"
              v-model="filters.type"
            >
              <option value="">全部类型</option>
              <option v-for="type in types" :key="type" :value="type">
                {{ type }}
              </option>
            </select>
          </div>
          
          <!-- 难度筛选 -->
          <div class="form-control">
            <label class="label cursor-pointer gap-2 pb-2">
              <i class="fas fa-signal text-primary"></i>
              <span class="label-text">难度</span>
            </label>
            <select 
              class="select select-bordered w-full bg-base-100/70 hover:bg-base-100 transition-colors"
              v-model="filters.difficulty"
            >
              <option value="">全部难度</option>
              <option v-for="n in 5" :key="n" :value="n" class="py-1">
                {{ '★'.repeat(n) }}{{ '☆'.repeat(5-n) }}
              </option>
            </select>
          </div>
          
          <!-- 状态筛选 -->
          <div class="form-control">
            <label class="label cursor-pointer gap-2 pb-2">
              <i class="fas fa-circle-check text-primary"></i>
              <span class="label-text">状态</span>
            </label>
            <select 
              class="select select-bordered w-full bg-base-100/70 hover:bg-base-100 transition-colors"
              v-model="filters.status"
            >
              <option value="">全部状态</option>
              <option value="available" class="text-warning">可开始</option>
              <option value="locked" class="text-error">未解锁</option>
              <option value="completed" class="text-success">已完成</option>
            </select>
          </div>
          <div class="form-control">
            <label class="label cursor-pointer gap-2 pb-2">
              <i class="fas fa-circle-check text-primary"></i>
              <span class="label-text">搜索</span>
            </label>
            <input
              type="text" 
              placeholder="搜索实践名称或描述..." 
              class="input input-bordered w-full pl-11 pr-4 bg-base-100/70 focus:bg-base-100
                     transition-all duration-300 shadow-sm hover:shadow focus:shadow-md"
              v-model="searchQuery"
            > 
          </div>
        </div>
      </div>
    </div>
    
    <!-- 实践列表 -->
    <div v-if="filteredModules.length" 
         class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 animate-fade-in">
      <ModuleOverView
        v-for="module in filteredModules"
        :key="module.id"
        :module="module"
        @start-experiment="handleStartExperiment"
      />
    </div>
    
    <!-- 无结果提示 -->
    <div v-else class="text-center py-12">
      <div class="text-6xl mb-4 text-base-content/30">
        <i class="fas fa-search"></i>
      </div>
      <h3 class="text-xl font-semibold mb-2">未找到匹配的实践</h3>
      <p class="text-base-content/70">
        试试调整筛选条件或重置筛选器
      </p>
      <button 
        class="btn btn-primary btn-sm mt-4"
        @click="resetFilters"
      >
        重置筛选器
      </button>
    </div>
  </div>
</template>

<style scoped>
.container-fluid {
  width: 100%;
  max-width: 100%;
  margin: 0 auto;
}

html, body {
  overflow-x: hidden;
  margin: 0;
  padding: 0;
  width: 100%;
}

.input-group > span {
  padding: 0 1rem;
  display: flex;
  align-items: center;
  color: var(--color-base-content/50);
}

.animate-fade-in {
  animation: fadeIn 0.3s ease-out;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* 统计卡片动画 */
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

/* 搜索框样式 */
.input {
  transition: all 0.3s ease;
}

.input:focus {
  outline: none;
  border-color: var(--color-primary);
}

/* 下拉框样式 */
.select {
  transition: all 0.3s ease;
}

.select:focus {
  outline: none;
  border-color: var(--color-primary);
}

/* 选项悬停效果 */
.select option {
  padding: 0.5rem;
}

.select option:hover {
  background-color: var(--color-primary);
  color: white;
}

/* 卡片内部边框 */
.border-b {
  border-bottom-width: 1px;
  border-color: rgba(var(--color-base-content), 0.1);
}

/* 磨砂玻璃效果 */
.backdrop-blur-sm {
  backdrop-filter: blur(8px);
}
</style>
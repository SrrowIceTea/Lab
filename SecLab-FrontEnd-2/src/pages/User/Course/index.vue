<script setup lang="ts">
import { getCourseVideoUrl, getCourseVideoUrlCandidates } from '../../../utils/videoUrl'
import { setVideoPosition, clearVideoPosition, setLabContext } from '../../../composables/useLabState'

// 定义课程接口

import {useRoute, useRouter} from "vue-router";
import { ref, onMounted, onUnmounted, computed, watch, type Ref } from 'vue'
import { CourseStatus } from "./index";
import type { Course } from "./index";
import {getCourseDetail} from "../../../api.ts";
import { getUserInfo } from '../../../api.ts'

const route = useRoute();
const router = useRouter();
const courseId = route.params.id;

// 添加错误提示状态
const errorMessage = ref<string | null>(null);

// 模拟课程数据
let course:Ref<Course> = ref({
  id: null,
  name: "",
  description: null,
  difficulty: null,
  type: null,
  tags: null,
  imageUrl: null,
  costTime: null,
  schedule: null,
  status: null,
  instructor: null,
  modules: []
})

// 用于模块依赖图的数据
const moduleItems = ref<any[]>([]);

// 添加学习进度（基于实际完成的模块数动态计算）
const learningProgress = ref(0);

// 动态计算学习进度：根据课程模块总数和实际完成数计算
function updateLearningProgress() {
  if (!course.value.modules || course.value.modules.length === 0) {
    learningProgress.value = 0;
    return;
  }
  // 默认初始化为0，后端接入后应从API获取实际完成数
  learningProgress.value = 0;
}

// 添加课程资源
const courseResources = ref([
  { name: '课程PPT', type: 'pdf', icon: 'file-pdf', size: '2.5MB' },
  { name: '课堂学习单', type: 'doc', icon: 'file-word', size: '1.8MB' },
  { name: '参考资料', type: 'link', icon: 'link', url: '#' },
  { name: '课程视频', type: 'video', icon: 'video', size: '完整版' }
]);

// 添加相关课程
const relatedCourses = ref([
  { id: 2, name: '第2讲 机器眼中的大千世界', similarity: 95, students: 1280 },
  { id: 5, name: '第5讲 机器自我成长进步', similarity: 88, students: 1105 },
  { id: 9, name: '第9讲 舞动科技的音符', similarity: 76, students: 860 }
]);

// 课堂实践任务（与十讲课程一一对应，ID 与模块种子保持一致）
const recommendedExperiments = ref([
  { id: 1, name: 'AI 应用大搜索', type: '课堂实践', difficulty: 1, tags: ['AI发展史', '场景调研'], estimatedTime: '30分钟' },
  { id: 2, name: '图像识别初体验', type: '课堂实践', difficulty: 2, tags: ['计算机视觉', '图像识别'], estimatedTime: '45分钟' },
  { id: 3, name: '让机器给句子分类', type: '课堂实践', difficulty: 2, tags: ['自然语言处理', '情感分析'], estimatedTime: '45分钟' },
  { id: 4, name: '搭一个知识图谱', type: '课堂实践', difficulty: 3, tags: ['认知推理', '知识图谱'], estimatedTime: '60分钟' },
  { id: 5, name: '训练第一个分类器', type: '课堂实践', difficulty: 3, tags: ['机器学习', '分类模型'], estimatedTime: '60分钟' },
  { id: 6, name: '设计一台服务机器人', type: '课堂实践', difficulty: 2, tags: ['智能机器人', '流程设计'], estimatedTime: '45分钟' },
  { id: 7, name: '多智能体协作推演', type: '课堂实践', difficulty: 4, tags: ['多智能体', '协作策略'], estimatedTime: '60分钟' },
  { id: 8, name: '搭建简易物理仿真', type: '课堂实践', difficulty: 4, tags: ['仿真模拟', '物理引擎'], estimatedTime: '60分钟' },
  { id: 9, name: '生成一段 AI 旋律', type: '课堂实践', difficulty: 2, tags: ['AI音乐', '旋律生成'], estimatedTime: '40分钟' },
  { id: 10, name: '我的 AI 学习计划', type: '课堂实践', difficulty: 1, tags: ['学习规划', 'AI素养'], estimatedTime: '30分钟' }
]);

// 跳转到课堂实践模块
const goToExperiment = (experimentId: number) => {
  console.log(`跳转到课堂实践模块: ${experimentId}`);
  router.push(`/user/module/${experimentId}`);
};

onMounted( async ()=>{
  try {
    // 直接使用本地数据，提高加载速度
    console.log('Using local fallback data for course detail');
    
    // 从本地课程列表中获取对应ID的课程数据
    const courseIdNum = Number(courseId);
    const allCourses = [
      {
        id: 1,
        name: '第1讲 人工智能的现状、趋势与战略',
        description: '从 ChatGPT 到自动驾驶，梳理人工智能的发展脉络、关键技术路线与产业战略布局，建立对 AI 的整体认知。',
        difficulty: 2,
        type: 'ai-basic',
        tags: ['AI发展史', '技术趋势', '战略布局'],
        imageUrl: '/ai/01.svg',
        costTime: 1,
        schedule: '第 1 讲',
        status: 'active',
        instructor: '北大 AI 微课讲师团',
        modules: [
          {
            moduleId: 1,
            moduleName: 'AI 应用大搜索',
            introduction: '在身边找出 5 个 AI 应用场景，分析它们解决了什么问题',
            type: ['人工智能基础'],
            difficulty: 1
          }
        ]
      },
      {
        id: 2,
        name: '第2讲 机器眼中的大千世界：计算机视觉',
        description: '看懂机器如何“看见”世界：图像采集、特征提取与卷积神经网络，理解人脸识别、自动驾驶感知背后的原理。',
        difficulty: 3,
        type: 'ai-perception',
        tags: ['计算机视觉', '图像识别', '卷积神经网络'],
        imageUrl: '/ai/02.svg',
        costTime: 2,
        schedule: '第 2 讲',
        status: 'active',
        instructor: '北大 AI 微课讲师团',
        modules: [
          {
            moduleId: 2,
            moduleName: '图像识别初体验',
            introduction: '用在线图像分类模型测试 10 张图片，记录识别结果与错误原因',
            type: ['感知智能'],
            difficulty: 2
          }
        ]
      },
      {
        id: 3,
        name: '第3讲 语言与机器的火花碰撞：自然语言处理',
        description: '从分词、词向量到大语言模型，理解机器如何理解与生成人类语言，以及机器翻译、智能问答的实现思路。',
        difficulty: 3,
        type: 'ai-perception',
        tags: ['自然语言处理', '大语言模型', '机器翻译'],
        imageUrl: '/ai/03.svg',
        costTime: 2,
        schedule: '第 3 讲',
        status: 'active',
        instructor: '北大 AI 微课讲师团',
        modules: [
          {
            moduleId: 3,
            moduleName: '让机器给句子分类',
            introduction: '用情感分析工具处理影评文本，观察分词与词向量的作用',
            type: ['感知智能'],
            difficulty: 2
          }
        ]
      },
      {
        id: 4,
        name: '第4讲 认知科学与 AI 世界的邀约：认知推理',
        description: '走进认知科学与 AI 的交叉地带：知识表示、逻辑推理与常识判断，看机器如何像人一样思考与决策。',
        difficulty: 4,
        type: 'ai-cognition',
        tags: ['认知科学', '知识图谱', '逻辑推理'],
        imageUrl: '/ai/04.svg',
        costTime: 2,
        schedule: '第 4 讲',
        status: 'active',
        instructor: '北大 AI 微课讲师团',
        modules: [
          {
            moduleId: 4,
            moduleName: '搭一个知识图谱',
            introduction: '为校园场景构建小型知识图谱，设计实体、关系与推理规则',
            type: ['认知与决策'],
            difficulty: 3
          }
        ]
      },
      {
        id: 5,
        name: '第5讲 机器自我成长进步：机器学习',
        description: '从数据到模型：监督学习、无监督学习与强化学习的基本范式，动手理解机器如何从经验中自我进化。',
        difficulty: 3,
        type: 'ai-cognition',
        tags: ['机器学习', '神经网络', '强化学习'],
        imageUrl: '/ai/05.svg',
        costTime: 2,
        schedule: '第 5 讲',
        status: 'active',
        instructor: '北大 AI 微课讲师团',
        modules: [
          {
            moduleId: 5,
            moduleName: '训练第一个分类器',
            introduction: '用可视化平台训练一个鸢尾花分类模型，调参观察准确率变化',
            type: ['认知与决策'],
            difficulty: 3
          }
        ]
      },
      {
        id: 6,
        name: '第6讲 未来生活离不开的伙伴：智能机器人',
        description: '认识身边的智能机器人：感知—决策—执行闭环、运动规划与人机协作，展望机器人在生活场景中的落地应用。',
        difficulty: 2,
        type: 'ai-embodied',
        tags: ['智能机器人', '运动规划', '人机协作'],
        imageUrl: '/ai/06.svg',
        costTime: 1,
        schedule: '第 6 讲',
        status: 'active',
        instructor: '北大 AI 微课讲师团',
        modules: [
          {
            moduleId: 6,
            moduleName: '设计一台服务机器人',
            introduction: '围绕校园导览场景，画出机器人的感知—决策—执行流程',
            type: ['具身智能'],
            difficulty: 2
          }
        ]
      },
      {
        id: 7,
        name: '第7讲 机器世界不孤单：多智能体',
        description: '当多个智能体同处一个世界：协作、博弈与群体智能，理解无人机编队、交通调度背后的多智能体系统。',
        difficulty: 4,
        type: 'ai-embodied',
        tags: ['多智能体', '群体智能', '博弈协同'],
        imageUrl: '/ai/07.svg',
        costTime: 2,
        schedule: '第 7 讲',
        status: 'active',
        instructor: '北大 AI 微课讲师团',
        modules: [
          {
            moduleId: 7,
            moduleName: '多智能体协作推演',
            introduction: '在仿真环境中为 3 个智能体设计协作策略并观察群体行为',
            type: ['具身智能'],
            difficulty: 4
          }
        ]
      },
      {
        id: 8,
        name: '第8讲 机器生活的世界：物理世界仿真模拟',
        description: '在虚拟世界中训练真实智能：物理引擎、数字孪生与仿真环境，理解 AI 如何借助模拟加速学习与验证。',
        difficulty: 4,
        type: 'ai-embodied',
        tags: ['仿真模拟', '数字孪生', '物理引擎'],
        imageUrl: '/ai/08.svg',
        costTime: 2,
        schedule: '第 8 讲',
        status: 'active',
        instructor: '北大 AI 微课讲师团',
        modules: [
          {
            moduleId: 8,
            moduleName: '搭建简易物理仿真',
            introduction: '用物理引擎模拟小球碰撞，理解仿真环境如何生成训练数据',
            type: ['具身智能'],
            difficulty: 4
          }
        ]
      },
      {
        id: 9,
        name: '第9讲 舞动科技的音符：人工智能音乐',
        description: 'AI 如何创作音乐：音频特征、旋律生成与风格迁移，体验人工智能在艺术创作中的可能性与边界。',
        difficulty: 2,
        type: 'ai-creative',
        tags: ['AI音乐', '旋律生成', '风格迁移'],
        imageUrl: '/ai/09.svg',
        costTime: 1,
        schedule: '第 9 讲',
        status: 'active',
        instructor: '北大 AI 微课讲师团',
        modules: [
          {
            moduleId: 9,
            moduleName: '生成一段 AI 旋律',
            introduction: '用 AI 作曲工具生成 8 小节旋律，比较不同风格参数的效果',
            type: ['智能创作'],
            difficulty: 2
          }
        ]
      },
      {
        id: 10,
        name: '第10讲 人工智能在北大',
        description: '走进北京大学的 AI 课堂与实验室，了解人工智能的前沿研究方向与拔尖创新人才培养路径。',
        difficulty: 1,
        type: 'ai-basic',
        tags: ['北大课堂', '前沿研究', 'AI人才培养'],
        imageUrl: '/ai/10.svg',
        costTime: 1,
        schedule: '第 10 讲',
        status: 'active',
        instructor: '北大 AI 微课讲师团',
        modules: [
          {
            moduleId: 10,
            moduleName: '我的 AI 学习计划',
            introduction: '结合十讲内容，制定一份面向自己的 AI 学习路线图',
            type: ['人工智能基础'],
            difficulty: 1
          }
        ]
      }
    ];
    // 查找对应ID的课程
    const foundCourse = allCourses.find(c => c.id === courseIdNum);
    if (foundCourse) {
      course.value = foundCourse;
      // 更新模块依赖图数据
      moduleItems.value = course.value.modules.map(module => ({
        id: module.moduleId,
        name: module.moduleName,
        description: module.introduction,
        difficulty: module.difficulty,
        type: module.type ? module.type.join(', ') : "",
        status: 'available' as 'available' | 'completed' | 'locked',
        prerequisites: [], // 假设模块没有prerequisites属性
        estimatedTime: "2-3小时"
      }));
    } else {
      console.warn('Course not found, using default data');
      // 使用默认数据
      course.value = {
        id: courseIdNum,
        name: '课程名称',
        description: '课程描述',
        difficulty: 3,
        type: 'web',
        tags: [],
        imageUrl: '',
        costTime: 8,
        schedule: '',
        status: 'active',
        instructor: '教授',
        modules: []
      };
    }
  } catch (error) {
    console.error('Failed to load course data:', error);
    // 使用默认数据
    course.value = {
      id: Number(courseId),
      name: '课程名称',
      description: '课程描述',
      difficulty: 3,
      type: 'web',
      tags: [],
      imageUrl: '',
      costTime: 8,
      schedule: '',
      status: 'active',
      instructor: '教授',
      modules: []
    };
  }
})

// 选择模块时的跳转处理
const handleSelectModule = (moduleId: number) => {
  router.push(`/user/module/${moduleId}`);
};

// 获取课程状态对应的标签样式
const getStatusBadgeClass = (status: CourseStatus | null) => {
  if (!status) return 'badge-neutral';
  const classes = {
    [CourseStatus.ACTIVE]: 'badge-success',
    [CourseStatus.UPCOMING]: 'badge-warning',
    [CourseStatus.COMPLETED]: 'badge-neutral'
  }
  return classes[status];
}

// 获取状态的中文描述
const getStatusText = (status: CourseStatus | null) => {
  if (!status) return '未知';
  const text = {
    [CourseStatus.ACTIVE]: '进行中',
    [CourseStatus.UPCOMING]: '即将开始',
    [CourseStatus.COMPLETED]: '已结束'
  }
  return text[status];
}

// Add a helper function to render stars
const getDifficultyStars = (difficulty: number | null) => {
  if (difficulty === null) return '未知';
  return '★'.repeat(difficulty) + '☆'.repeat(5 - difficulty);
}

// 课程类型的中文名称
const TYPE_NAMES: Record<string, string> = {
  'ai-basic': '人工智能基础',
  'ai-perception': '感知智能',
  'ai-cognition': '认知与决策',
  'ai-embodied': '具身智能',
  'ai-creative': '智能创作'
};

const getTypeName = (type: string | null) => {
  if (!type) return '未分类';
  return TYPE_NAMES[type] || type;
};

// 添加难度等级描述
const getDifficultyText = (difficulty: number | null) => {
  if (difficulty === null) return '未知';
  const levels = {
    1: '入门',
    2: '基础',
    3: '进阶',
    4: '困难',
    5: '专家'
  }
  return levels[difficulty as keyof typeof levels];
}

// 添加动画控制状态
const isPageLoaded = ref(false)
const isContentVisible = ref(false)

function onButtonClick(id:number | null){
  if (id === null) return;
  router.push(`/user/module/${id}`);
}

onMounted(() => {
  isPageLoaded.value = true
  setTimeout(() => {
    isContentVisible.value = true
  }, 100)
})

// 把当前课程写进全局上下文：右下角 AI 助手据此检索教师为该课程上传的资料（RAG）
watch(
  () => [course.value?.id, course.value?.name] as const,
  ([id, name]) => {
    if (id) {
      setLabContext({ courseId: Number(id), courseName: name || '' })
    }
  },
  { immediate: true }
)

// 用户信息
const userInfo = ref({
  userName: '',
  userStudentNumber: '',
  userImage: ''
  // ...其他字段
})

// 获取token（假设保存在localStorage）
const token = localStorage.getItem('token') || ''

onMounted(async () => {
  if (token) {
    const res = await getUserInfo(token)
    if (res.isSuccess === 1 && res.data) {
      // 确保userImage不为undefined
      userInfo.value = {
        userName: res.data.userName || '',
        userStudentNumber: res.data.userStudentNumber || '',
        userImage: res.data.userImage || ''
      }
    }
  }
})

// 获取配套实践任务
const getRecommendedExperiments = (courseId: number | null) => {
  if (!courseId) return [];

  // 本讲任务优先，再补充下一讲任务作为延伸练习
  const primary = recommendedExperiments.value.filter((exp) => exp.id === courseId);
  const next = recommendedExperiments.value.filter((exp) => exp.id === courseId + 1);
  return [...primary, ...next].slice(0, 2);
};

// 开始任务
const startExperiment = (experimentId: number) => {
  console.log(`开始任务: ${experimentId}`);
  router.push(`/user/module/${experimentId}`);
};

// 第 X 讲视频标题
const VIDEO_TITLES: Record<number, string> = {
  1: '第1讲 人工智能的现状、趋势与战略',
  2: '第2讲 机器眼中的大千世界：计算机视觉',
  3: '第3讲 语言与机器的火花碰撞：自然语言处理',
  4: '第4讲 认知科学与 AI 世界的邀约：认知推理',
  5: '第5讲 机器自我成长进步：机器学习',
  6: '第6讲 未来生活离不开的伙伴：智能机器人',
  7: '第7讲 机器世界不孤单：多智能体',
  8: '第8讲 机器生活的世界：物理世界仿真模拟',
  9: '第9讲 舞动科技的音符：人工智能音乐',
  10: '第10讲 人工智能在北大',
};

// 第 X 讲视频简介
const VIDEO_DESCRIPTIONS: Record<number, string> = {
  1: '第1讲 人工智能的现状、趋势与战略 完整课程录像',
  2: '计算机视觉 完整课程录像',
  3: '自然语言处理 完整课程录像',
  4: '认知推理 完整课程录像',
  5: '机器学习 完整课程录像',
  6: '智能机器人 完整课程录像',
  7: '多智能体 完整课程录像',
  8: '物理世界仿真模拟 完整课程录像',
  9: '人工智能音乐 完整课程录像',
  10: '第10讲 人工智能在北大 完整课程录像',
};

const getVideoTitle = (courseId: number | null, _videoIndex = 1) => {
  if (!courseId) return '未知视频';
  return VIDEO_TITLES[courseId] || '未知视频';
};

const getVideoDescription = (courseId: number | null, _videoIndex = 1) => {
  if (!courseId) return '暂无描述';
  return VIDEO_DESCRIPTIONS[courseId] || '暂无描述';
};

// 当前课程的视频地址（阿里云 OSS 公共读 bucket）
const videoUrl = computed(() => {
  const id = course.value.id;
  if (!id || id < 1 || id > 10) return '';
  return getCourseVideoUrl(id);
});

// OSS 候选地址：先试 video/ 目录，再试桶根目录，避免上传目录不同导致 404
const videoUrls = computed(() => {
  const id = course.value.id;
  if (!id || id < 1 || id > 10) return [];
  return getCourseVideoUrlCandidates(id);
});

// ─────────────────────────────────────────
//  视频伴侣：章节索引 / 三分钟摘要 / 讲中答疑
// ─────────────────────────────────────────
const AGENT_BASE_URL = import.meta.env.VITE_AGENT_BASE_URL || 'http://localhost:8010'
const videoRef = ref<HTMLVideoElement | null>(null)
const currentSeconds = ref(0)
const chapters = ref<Array<{ index: number; start: string; startSec: number; end: string; title: string }>>([])
const summary = ref('')
const summaryLoading = ref(false)
const companionOpen = ref(false)
const askQuestion = ref('')
const askAnswer = ref('')
const asking = ref(false)
const showSummary = ref(false)

const lectureId = computed(() => {
  const id = course.value?.id
  return id && id >= 1 && id <= 10 ? id : 0
})

function onVideoTimeUpdate() {
  if (videoRef.value) {
    currentSeconds.value = Math.floor(videoRef.value.currentTime)
    const id = lectureId.value
    if (id) setVideoPosition(id, currentSeconds.value)
  }
}

function seekTo(seconds: number) {
  if (videoRef.value) {
    videoRef.value.currentTime = seconds
    videoRef.value.play().catch(() => {})
  }
}

function formatTime(sec: number): string {
  const m = Math.floor(sec / 60)
  const s = Math.floor(sec % 60)
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
}

async function loadCompanion(id: number) {
  chapters.value = []
  summary.value = ''
  try {
    const [chRes, sumRes] = await Promise.all([
      fetch(`${AGENT_BASE_URL}/api/video/chapters?lecture=${id}`),
      fetch(`${AGENT_BASE_URL}/api/video/summary?lecture=${id}`)
    ])
    if (chRes.ok) chapters.value = (await chRes.json()).chapters || []
    if (sumRes.ok) summary.value = (await sumRes.json()).summary || ''
  } catch (err) {
    console.warn('视频伴侣数据加载失败:', err)
  }
}

watch(lectureId, (id) => {
  if (id) void loadCompanion(id)
}, { immediate: true })

onUnmounted(() => {
  clearVideoPosition()
  // 离开课程页时清掉课程上下文，避免影响其他页面的对话
  setLabContext({ courseId: null, courseName: '' })
})

function openCompanion() {
  companionOpen.value = true
  if (!askQuestion.value) askQuestion.value = '这里我没懂，请结合当前视频内容解释一下'
}

async function askAboutVideo() {
  const id = lectureId.value
  if (!id || !askQuestion.value.trim() || asking.value) return
  asking.value = true
  askAnswer.value = ''
  try {
    const response = await fetch(`${AGENT_BASE_URL}/api/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        query: askQuestion.value.trim(),
        conversation_id: '',
        user: 'student',
        inputs: {},
        lab_context: {
          moduleId: id,
          moduleName: course.value?.name || '',
          courseId: id,
          currentTask: '视频学习中'
        },
        videoPosition: { lecture: id, seconds: currentSeconds.value }
      })
    })
    if (!response.ok || !response.body) throw new Error(`HTTP ${response.status}`)
    const reader = response.body.getReader()
    const decoder = new TextDecoder('utf-8')
    let buffer = ''
    while (true) {
      const { done, value } = await reader.read()
      if (done) break
      buffer += decoder.decode(value, { stream: true })
      const lines = buffer.split('\n')
      buffer = lines.pop() || ''
      for (const line of lines) {
        if (!line.startsWith('data:')) continue
        const raw = line.slice(5).trim()
        if (!raw || raw === '[DONE]') continue
        try {
          const evt = JSON.parse(raw)
          if (evt.event === 'message' && evt.answer) askAnswer.value += evt.answer
          if (evt.event === 'error') askAnswer.value += `\n[错误] ${evt.message}`
        } catch { /* 忽略解析失败的行 */ }
      }
    }
  } catch (err: any) {
    askAnswer.value = `答疑失败：${err?.message || err}`
  } finally {
    asking.value = false
  }
}
</script>

<template>
  <div class="container-fluid px-4 py-6 overflow-x-hidden" :class="{ 'fade-in': isPageLoaded }">
    <!-- 错误提示 -->
    <div v-if="errorMessage" class="alert alert-error mb-4">
      <i class="fas fa-exclamation-circle"></i>
      <span>{{ errorMessage }}</span>
    </div>
    
    <!-- 返回按钮 -->
    <div class="mb-4 slide-in-top">
      <button @click="router.go(-1)" class="btn btn-sm btn-ghost gap-2 hover:bg-base-200">
        <i class="fas fa-arrow-left"></i>
        <span>返回</span>
      </button>
    </div>
    
    <!-- 页面顶部：课程标题和状态 -->
    <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-8 slide-in-top">
      <div class="flex items-center gap-4">
        <div class="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center">
          <i class="fas fa-graduation-cap text-2xl text-primary"></i>
        </div>
        <div>
          <h1 class="text-3xl font-bold hover:scale-[1.02] transition-transform">{{ course.name }}</h1>
        </div>
      </div>
      <div class="flex items-center gap-3">
        <div :class="[
          'badge badge-lg py-3 px-4 gap-2 transition-all animate-pulse', 
          getStatusBadgeClass(course.status)
        ]">
          <span class="w-2 h-2 rounded-full bg-current"></span>
          <span class="font-medium">{{ getStatusText(course.status) }}</span>
        </div>
        <button class="btn btn-primary btn-sm gap-2 hidden md:flex">
          <i class="fas fa-bookmark"></i>
          收藏课程
        </button>
      </div>
    </div>

    <!-- 课程信息卡片 -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
      <!-- 左侧：课程简介 -->
      <div class="lg:col-span-1">
        <div class="card bg-base-100 shadow-xl hover:shadow-2xl transition-all duration-300 h-full"
            :class="{ 'slide-in-left': isContentVisible }">
          <div class="card-body">
            <!-- 课程简介 -->
            <div class="mb-4">
              <div class="flex items-center gap-3 mb-3">
                <div class="w-10 h-10 rounded-lg bg-primary/10 flex items-center justify-center">
                  <i class="fas fa-info-circle text-xl text-primary"></i>
                </div>
                <h2 class="text-xl font-semibold">课程简介</h2>
              </div>
              <div class="pl-2 space-y-2 text-base-content/80 text-sm">
                <p class="whitespace-pre-line">{{ course.description }}</p>
              </div>
            </div>
            
            <!-- 课程标签 -->
            <div v-if="course.tags && course.tags.length > 0" class="mb-4">
              <div class="flex items-center gap-2 mb-3">
                <i class="fas fa-tags text-primary"></i>
                <h3 class="font-medium">课程标签</h3>
              </div>
              <div class="flex flex-wrap gap-2 pl-2">
                <span v-for="tag in course.tags" :key="tag" class="badge badge-outline">{{ tag }}</span>
              </div>
            </div>
            
            <!-- 课程信息 -->
            <div class="grid grid-cols-1 gap-2 mb-4">
              <div v-if="course.instructor" class="flex items-center gap-2">
                <i class="fas fa-chalkboard-teacher w-5 text-center text-primary"></i>
                <span class="text-sm">讲师：{{ course.instructor }}</span>
              </div>
              <div v-if="course.difficulty" class="flex items-center gap-2">
                <i class="fas fa-signal w-5 text-center text-primary"></i>
                <span class="text-sm">
                  难度：
                  <span class="text-yellow-500">{{ getDifficultyStars(course.difficulty) }}</span>
                  ({{ getDifficultyText(course.difficulty) }})
                </span>
              </div>
              <div v-if="course.costTime" class="flex items-center gap-2">
                <i class="fas fa-clock w-5 text-center text-primary"></i>
                <span class="text-sm">课时：{{ course.costTime }}</span>
              </div>
              <div v-if="course.type" class="flex items-center gap-2">
                <i class="fas fa-bookmark w-5 text-center text-primary"></i>
                <span class="text-sm">类型：{{ getTypeName(course.type) }}</span>
              </div>
              <div v-if="course.schedule" class="flex items-center gap-2">
                <i class="fas fa-calendar-alt w-5 text-center text-primary"></i>
                <span class="text-sm">课程安排：{{ course.schedule }}</span>
              </div>
            </div>
            
            <!-- 课程资源 -->
            <div v-if="courseResources.length > 0" class="mb-4">
              <div class="flex items-center gap-2 mb-3">
                <i class="fas fa-download text-primary"></i>
                <h3 class="font-medium">课程资源</h3>
              </div>
              <div class="space-y-2 pl-2">
                <div v-for="resource in courseResources" :key="resource.name"
                    class="bg-base-200 p-2 rounded-lg flex justify-between items-center hover:bg-base-300 transition-colors">
                  <div class="flex items-center gap-2">
                    <i :class="`fas fa-${resource.icon} text-primary`"></i>
                    <span class="text-sm">{{ resource.name }}</span>
                  </div>
                  <div class="flex items-center">
                    <span v-if="resource.size" class="text-xs text-base-content/60 mr-2">{{ resource.size }}</span>
                    <button class="btn btn-xs btn-ghost btn-circle">
                      <i class="fas fa-download"></i>
                    </button>
                  </div>
                </div>
              </div>
            </div>
            
            <!-- 进度 -->
            <div class="mt-auto">
              <div class="flex items-center justify-between mb-2">
                <span class="text-sm font-medium">学习进度</span>
                <span class="text-sm font-bold text-primary">{{ learningProgress }}%</span>
              </div>
              <div class="w-full bg-base-200 rounded-full h-2.5">
                <div class="bg-primary h-2.5 rounded-full" :style="{ width: `${learningProgress}%` }"></div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 右侧：视频区域（占据2/3宽度） -->
      <div class="lg:col-span-2">
        <!-- 课程视频卡片 -->
        <div class="card bg-base-100 shadow-xl hover:shadow-2xl transition-all duration-300 h-full"
             :class="{ 'slide-in-right': isContentVisible }">
          <div class="card-body p-4">
            <div class="flex items-center gap-2 mb-3">
              <i class="fas fa-video text-xl text-primary"></i>
              <h2 class="text-xl font-semibold">课程视频</h2>
              <span class="badge badge-primary badge-sm ml-2">视频教程</span>
            </div>
            
            <!-- 视频区域 -->
            <div class="grid grid-cols-1 lg:grid-cols-3 gap-4">
              <!-- 主视频区域 -->
              <div class="lg:col-span-3">
                <div class="bg-base-200 rounded-xl overflow-hidden shadow-lg">
                  <!-- 视频播放器区域 -->
                  <div class="aspect-video w-full">
                    <video
                      v-if="videoUrl"
                      ref="videoRef"
                      class="w-full"
                      controls
                      :key="videoUrl"
                      @timeupdate="onVideoTimeUpdate"
                    >
                      <source v-for="url in videoUrls" :key="url" :src="url" type="video/mp4" />
                      您的浏览器不支持 HTML5 视频播放。
                    </video>
                    <div v-else class="w-full h-full flex items-center justify-center bg-base-300">
                      <div class="text-center p-6">
                        <i class="fas fa-video-slash text-4xl text-base-content/50 mb-3"></i>
                        <p class="text-base-content/70">该课程暂无视频</p>
                      </div>
                    </div>
                  </div>
                  <!-- 视频信息 -->
                  <div class="p-4">
                    <h3 class="font-medium text-lg mb-2">{{ course.name }} · 主讲视频</h3>
                    <div class="flex items-center justify-between text-sm text-base-content/80 mb-3">
                      <div class="flex items-center gap-3">
                        <span><i class="fas fa-clock mr-1"></i> 完整版</span>
                        <span><i class="fas fa-graduation-cap mr-1"></i> 校本微课</span>
                      </div>
                      <div class="flex items-center gap-2">
                        <button class="btn btn-xs btn-outline btn-circle">
                          <i class="fas fa-thumbs-up"></i>
                        </button>
                        <button class="btn btn-xs btn-outline btn-circle">
                          <i class="fas fa-share"></i>
                        </button>
                      </div>
                    </div>
                    <p class="text-sm text-base-content/70">
                      本视频为《“立心之约”中学生 AI 微课十讲》配套课程录像，建议边看边记录关键概念，并在观看后完成本讲配套的课堂实践任务。
                    </p>

                    <!-- 视频伴侣工具条 -->
                    <div class="flex flex-wrap gap-2 mt-4 pt-3 border-t border-base-300">
                      <button class="btn btn-sm btn-outline" @click="showSummary = !showSummary">
                        <i class="fas fa-list-alt mr-1"></i>{{ showSummary ? '收起导读' : '三分钟导读' }}
                      </button>
                      <button class="btn btn-sm btn-primary" @click="openCompanion">
                        <i class="fas fa-question-circle mr-1"></i>这里没懂？问 AI
                      </button>
                      <span class="badge badge-ghost badge-sm ml-auto">
                        <i class="fas fa-clock mr-1"></i>{{ formatTime(currentSeconds) }}
                      </span>
                    </div>

                    <!-- 三分钟导读 -->
                    <div v-if="showSummary" class="mt-3 p-4 rounded-lg bg-primary/5 border border-primary/20">
                      <div class="flex items-center gap-2 mb-2">
                        <i class="fas fa-robot text-primary"></i>
                        <span class="font-medium text-sm">本讲导读</span>
                      </div>
                      <p v-if="summary" class="text-sm text-base-content/80 leading-relaxed">{{ summary }}</p>
                      <p v-else class="text-sm text-base-content/50">摘要加载中或暂不可用…</p>
                    </div>

                    <!-- 章节索引 -->
                    <div v-if="chapters.length" class="mt-4">
                      <div class="flex items-center gap-2 mb-2">
                        <i class="fas fa-list text-primary"></i>
                        <span class="font-medium text-sm">章节索引（点击跳转）</span>
                      </div>
                      <div class="flex flex-wrap gap-2">
                        <button
                          v-for="ch in chapters"
                          :key="ch.index"
                          class="btn btn-xs btn-outline"
                          @click="seekTo(ch.startSec)"
                        >
                          <span class="text-primary mr-1">{{ ch.start }}</span>{{ ch.title }}
                        </button>
                      </div>
                    </div>

                    <!-- 讲中答疑面板 -->
                    <div v-if="companionOpen" class="mt-4 p-4 rounded-lg bg-base-200">
                      <div class="flex items-center justify-between mb-2">
                        <div class="flex items-center gap-2">
                          <i class="fas fa-robot text-primary"></i>
                          <span class="font-medium text-sm">讲中答疑 · 基于当前画面</span>
                          <span class="badge badge-primary badge-sm">{{ formatTime(currentSeconds) }}</span>
                        </div>
                        <button class="btn btn-ghost btn-xs" @click="companionOpen = false">
                          <i class="fas fa-times"></i>
                        </button>
                      </div>
                      <div class="flex gap-2 mb-3">
                        <input
                          v-model="askQuestion"
                          class="input input-bordered input-sm flex-1"
                          placeholder="输入你的问题..."
                          @keyup.enter="askAboutVideo"
                        />
                        <button class="btn btn-primary btn-sm" :disabled="asking || !askQuestion.trim()" @click="askAboutVideo">
                          {{ asking ? '思考中…' : '提问' }}
                        </button>
                      </div>
                      <div v-if="askAnswer" class="p-3 rounded bg-base-100 text-sm leading-relaxed whitespace-pre-wrap">{{ askAnswer }}</div>
                      <p v-else class="text-xs text-base-content/50">
                        AI 会结合你当前播放位置附近讲的内容来回答，越具体的问题效果越好。
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            
            <!-- 本讲视频 -->
            <div class="mt-5 mb-3">
              <div class="flex items-center justify-between mb-3">
                <div class="flex items-center gap-2">
                  <i class="fas fa-list text-primary"></i>
                  <h3 class="font-medium text-lg">{{ course.name }} · 本讲视频</h3>
                </div>
                <span class="badge badge-sm">{{ videoUrl ? '1 个视频' : '暂无视频' }}</span>
              </div>
              
              <!-- 视频列表 -->
              <div v-if="videoUrl" class="grid grid-cols-1 gap-3">
                <div class="bg-base-200 p-3 rounded-lg border-l-4 border-primary">
                  <div class="flex items-center gap-2 mb-2">
                    <div class="w-10 h-10 rounded-lg bg-primary/20 flex items-center justify-center">
                      <i class="fas fa-play-circle text-primary"></i>
                    </div>
                    <div>
                      <h4 class="font-medium">{{ getVideoTitle(course.id, 1) }}</h4>
                      <span class="text-xs text-base-content/60">完整课程录像 · 高清</span>
                    </div>
                  </div>
                  <p class="text-xs text-base-content/70 line-clamp-2">{{ getVideoDescription(course.id, 1) }}</p>
                </div>
              </div>
              <div v-else class="bg-base-200 p-6 rounded-lg text-center">
                <i class="fas fa-film text-4xl text-base-content/30 mb-3"></i>
                <p class="text-base-content/70">该课程暂无视频</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 模块列表 -->
    <div class="card bg-base-100 shadow-xl hover:shadow-2xl transition-shadow duration-300"
         :class="{ 'slide-in-right': isContentVisible }">
      <div class="card-body">
        <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-4">
          <div class="flex items-center gap-2">
            <i class="fas fa-flask text-xl text-primary"></i>
            <h2 class="text-xl font-semibold">课程模块</h2>
            <span class="badge badge-primary">{{ course.modules.length }}个</span>
          </div>
          
          <!-- 筛选和搜索 -->
          <div class="flex flex-wrap gap-2">
            <div class="join">
              <button class="btn btn-sm join-item btn-active">全部</button>
              <button class="btn btn-sm join-item">实践</button>
              <button class="btn btn-sm join-item">理论</button>
            </div>
            <div class="form-control">
              <div class="input-group input-group-sm">
                <input type="text" placeholder="搜索模块..." class="input input-sm input-bordered" />
                <button class="btn btn-sm btn-square">
                  <i class="fas fa-search"></i>
                </button>
              </div>
            </div>
          </div>
        </div>
        
        <div class="grid gap-4">
          <div v-for="(module, index) in course.modules" 
               :key="module.moduleId || index"
               class="card bg-base-200 hover:bg-base-300 transition-all duration-200 fade-in-row"
               :style="{ animationDelay: `${index * 0.1}s` }">
            <div class="card-body p-4">
              <div class="flex justify-between items-start">
                <div class="space-y-2">
                  <h3 class="text-lg font-medium flex items-center gap-2">
                    <i class="fas fa-terminal text-primary"></i>
                    {{ module.moduleName }}
                    <span class="badge badge-sm" :class="index === 0 ? 'badge-accent' : ''">
                      {{ index === 0 ? '推荐开始' : `模块 ${index + 1}` }}
                    </span>
                  </h3>
                  <p class="text-sm text-gray-500">{{ module.introduction }}</p>
                  <div class="flex items-center gap-4 text-sm flex-wrap">
                    <div v-if="module.type && module.type.length > 0" class="flex items-center gap-1">
                      <i class="fas fa-bookmark text-primary"></i>
                      <span>{{ module.type.join(', ') }}</span>
                    </div>
                    <div class="flex items-center gap-1" :title="getDifficultyText(module.difficulty)">
                      <i class="fas fa-signal text-primary"></i>
                      <span class="text-yellow-500">{{ getDifficultyStars(module.difficulty) }}</span>
                    </div>
                    <div class="flex items-center gap-1">
                      <i class="fas fa-clock text-primary"></i>
                      <span>预计 {{ module.difficulty ? `${module.difficulty}-${module.difficulty + 1}小时` : '未知' }}</span>
                    </div>
                  </div>
                </div>
                <div class="flex flex-col gap-2 items-end">
                  <div class="badge" :class="index < Math.ceil(course.modules.length * learningProgress / 100) ? 'badge-success' : 'badge-outline'">
                    {{ index < Math.ceil(course.modules.length * learningProgress / 100) ? '已完成' : '待完成' }}
                  </div>
                  <button @click="onButtonClick(module.moduleId)" class="btn btn-primary btn-sm gap-2 hover:scale-105 transition-transform duration-200 mt-2">
                    <i class="fas fa-arrow-right text-sm"></i>
                    进入模块
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
        
        <!-- 添加分隔线 -->
        <div class="divider my-8">
          <div class="flex items-center gap-2">
            <i class="fas fa-fire-alt text-warning"></i>
            <span class="text-lg">课堂实践推荐</span>
          </div>
        </div>
        
        <!-- 推荐课堂实践 -->
        <div class="bg-gradient-to-r from-primary/5 to-secondary/5 p-4 rounded-lg mb-6 border border-primary/20">
          <div class="flex items-center justify-between mb-3">
            <div class="flex items-center gap-2">
              <i class="fas fa-lightbulb text-primary"></i>
              <h3 class="font-medium text-lg">{{ course.name }} 配套实践任务</h3>
              <span class="badge badge-sm badge-primary">可直接跳转</span>
            </div>
            <button class="btn btn-sm btn-outline btn-primary">
              <i class="fas fa-th-list mr-1"></i>
              查看全部
            </button>
          </div>
          <p class="text-sm text-base-content/70 mb-3">以下是《{{ course.name }}》的配套课堂实践任务，点击即可直接开始</p>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-3 mt-3">
            <div v-for="experiment in getRecommendedExperiments(course.id)" :key="experiment.id" 
                class="card bg-base-200/90 hover:bg-base-200 transition-all duration-300 hover:shadow-md border-l-4"
                :class="{
                  'border-error': experiment.difficulty >= 4,
                  'border-warning': experiment.difficulty === 3,
                  'border-success': experiment.difficulty <= 2
                }">
              <div class="card-body p-3">
                <div class="flex items-center justify-between">
                  <div>
                    <h4 class="font-medium">{{ experiment.name }}</h4>
                    <div class="flex items-center gap-2 mt-1">
                      <span class="text-xs text-base-content/60">
                        <i class="fas fa-signal mr-1"></i> 
                        {{ getDifficultyText(experiment.difficulty) }}
                      </span>
                      <span class="text-xs text-base-content/60">
                        <i class="fas fa-clock mr-1"></i> 
                        {{ experiment.estimatedTime }}
                      </span>
                    </div>
                  </div>
                  <button @click="startExperiment(experiment.id)" class="btn btn-xs btn-primary">
                    开始任务
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
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

html, body {
  overflow-x: hidden;
  margin: 0;
  padding: 0;
  width: 100%;
}

/* 基础淡入动画 */
.fade-in {
  animation: fadeIn 0.5s ease-out;
}

/* 从上滑入动画 */
.slide-in-top {
  animation: slideInTop 0.5s ease-out;
}

/* 从左滑入动画 */
.slide-in-left {
  animation: slideInLeft 0.5s ease-out;
}

/* 从右滑入动画 */
.slide-in-right {
  animation: slideInRight 0.5s ease-out;
}

/* 表格行淡入动画 */
.fade-in-row {
  opacity: 0;
  animation: fadeIn 0.5s ease-out forwards;
}

@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

/* 从顶部滑入 */
.slide-in-top {
  animation: slideInTop 0.7s ease-out;
}

@keyframes slideInTop {
  from {
    transform: translateY(-20px);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}

@keyframes slideInLeft {
  from {
    transform: translateX(-20px);
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
}

@keyframes slideInRight {
  from {
    transform: translateX(20px);
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
}

/* 添加图标悬停效果 */
.fas {
  transition: transform 0.2s ease;
}

.fas:hover {
  transform: scale(1.1);
}

/* 调整卡片过渡效果 */
.card {
  transition: all 0.3s ease;
}

.card:hover {
  transform: translateY(-2px);
}
</style>

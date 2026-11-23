import { getCourseVideoUrl } from '../utils/videoUrl'
import type { CourseSummaryDto } from '../api'
import type { Course } from '../types/course'
import type { Experiment } from '../types/experiment'
import type { ModuleOverViewType } from '../pages/User/Modules/components/ModuleOverView'
import type { CourseOverViewType } from '../pages/User/Courses/components/CourseOverView'

type PresentationCourseSeed = {
  id: number
  name: string
  description: string
  difficulty: 1 | 2 | 3 | 4 | 5
  type: string
  category: string
  cover: string
  videoUrl?: string
  tags: string[]
}

type PresentationModuleSeed = {
  id: number
  name: string
  description: string
  difficulty: 1 | 2 | 3 | 4 | 5
  type: string
  estimatedTime: string
  score: number
  courseId: number
  courseName: string
}

export const PRESENTATION_TOTAL_USERS = 128
export const PRESENTATION_CLASS_SCORE = 76

export const PRESENTATION_COURSE_SEEDS: PresentationCourseSeed[] = [
  {
    id: 1,
    name: '第1讲 人工智能的现状、趋势与战略',
    description: '从 ChatGPT 到自动驾驶，梳理人工智能的发展脉络、关键技术路线与产业战略布局，建立对 AI 的整体认知。',
    difficulty: 2,
    type: 'ai-basic',
    category: '人工智能基础',
    cover: '/ai/01.svg',
    videoUrl: getCourseVideoUrl(1),
    tags: ['AI发展史', '技术趋势', '战略布局'],
  },
  {
    id: 2,
    name: '第2讲 机器眼中的大千世界：计算机视觉',
    description: '看懂机器如何“看见”世界：图像采集、特征提取与卷积神经网络，理解人脸识别、自动驾驶感知背后的原理。',
    difficulty: 3,
    type: 'ai-perception',
    category: '感知智能',
    cover: '/ai/02.svg',
    videoUrl: getCourseVideoUrl(2),
    tags: ['计算机视觉', '图像识别', '卷积神经网络'],
  },
  {
    id: 3,
    name: '第3讲 语言与机器的火花碰撞：自然语言处理',
    description: '从分词、词向量到大语言模型，理解机器如何理解与生成人类语言，以及机器翻译、智能问答的实现思路。',
    difficulty: 3,
    type: 'ai-perception',
    category: '感知智能',
    cover: '/ai/03.svg',
    videoUrl: getCourseVideoUrl(3),
    tags: ['自然语言处理', '大语言模型', '机器翻译'],
  },
  {
    id: 4,
    name: '第4讲 认知科学与 AI 世界的邀约：认知推理',
    description: '走进认知科学与 AI 的交叉地带：知识表示、逻辑推理与常识判断，看机器如何像人一样思考与决策。',
    difficulty: 4,
    type: 'ai-cognition',
    category: '认知与决策',
    cover: '/ai/04.svg',
    videoUrl: getCourseVideoUrl(4),
    tags: ['认知科学', '知识图谱', '逻辑推理'],
  },
  {
    id: 5,
    name: '第5讲 机器自我成长进步：机器学习',
    description: '从数据到模型：监督学习、无监督学习与强化学习的基本范式，动手理解机器如何从经验中自我进化。',
    difficulty: 3,
    type: 'ai-cognition',
    category: '认知与决策',
    cover: '/ai/05.svg',
    videoUrl: getCourseVideoUrl(5),
    tags: ['机器学习', '神经网络', '强化学习'],
  },
  {
    id: 6,
    name: '第6讲 未来生活离不开的伙伴：智能机器人',
    description: '认识身边的智能机器人：感知—决策—执行闭环、运动规划与人机协作，展望机器人在生活场景中的落地应用。',
    difficulty: 2,
    type: 'ai-embodied',
    category: '具身智能',
    cover: '/ai/06.svg',
    videoUrl: getCourseVideoUrl(6),
    tags: ['智能机器人', '运动规划', '人机协作'],
  },
  {
    id: 7,
    name: '第7讲 机器世界不孤单：多智能体',
    description: '当多个智能体同处一个世界：协作、博弈与群体智能，理解无人机编队、交通调度背后的多智能体系统。',
    difficulty: 4,
    type: 'ai-embodied',
    category: '具身智能',
    cover: '/ai/07.svg',
    videoUrl: getCourseVideoUrl(7),
    tags: ['多智能体', '群体智能', '博弈协同'],
  },
  {
    id: 8,
    name: '第8讲 机器生活的世界：物理世界仿真模拟',
    description: '在虚拟世界中训练真实智能：物理引擎、数字孪生与仿真环境，理解 AI 如何借助模拟加速学习与验证。',
    difficulty: 4,
    type: 'ai-embodied',
    category: '具身智能',
    cover: '/ai/08.svg',
    videoUrl: getCourseVideoUrl(8),
    tags: ['仿真模拟', '数字孪生', '物理引擎'],
  },
  {
    id: 9,
    name: '第9讲 舞动科技的音符：人工智能音乐',
    description: 'AI 如何创作音乐：音频特征、旋律生成与风格迁移，体验人工智能在艺术创作中的可能性与边界。',
    difficulty: 2,
    type: 'ai-creative',
    category: '智能创作',
    cover: '/ai/09.svg',
    videoUrl: getCourseVideoUrl(9),
    tags: ['AI音乐', '旋律生成', '风格迁移'],
  },
  {
    id: 10,
    name: '第10讲 人工智能在北大',
    description: '走进北京大学的 AI 课堂与实验室，了解人工智能的前沿研究方向与拔尖创新人才培养路径。',
    difficulty: 1,
    type: 'ai-basic',
    category: '人工智能基础',
    cover: '/ai/10.svg',
    videoUrl: getCourseVideoUrl(10),
    tags: ['北大课堂', '前沿研究', 'AI人才培养'],
  },
]

export const PRESENTATION_MODULE_SEEDS: PresentationModuleSeed[] = [
  { id: 1, name: 'AI 应用大搜索', description: '在身边找出 5 个 AI 应用场景，分析它们解决了什么问题。', difficulty: 1, type: '人工智能基础', estimatedTime: '30分钟', score: 40, courseId: 1, courseName: '第1讲 人工智能的现状、趋势与战略' },
  { id: 2, name: '图像识别初体验', description: '用在线图像分类模型测试 10 张图片，记录识别结果与错误原因。', difficulty: 2, type: '感知智能', estimatedTime: '45分钟', score: 55, courseId: 2, courseName: '第2讲 机器眼中的大千世界：计算机视觉' },
  { id: 3, name: '让机器给句子分类', description: '用情感分析工具处理影评文本，观察分词与词向量的作用。', difficulty: 2, type: '感知智能', estimatedTime: '45分钟', score: 55, courseId: 3, courseName: '第3讲 语言与机器的火花碰撞：自然语言处理' },
  { id: 4, name: '搭一个知识图谱', description: '为校园场景构建小型知识图谱，设计实体、关系与推理规则。', difficulty: 3, type: '认知与决策', estimatedTime: '60分钟', score: 70, courseId: 4, courseName: '第4讲 认知科学与 AI 世界的邀约：认知推理' },
  { id: 5, name: '训练第一个分类器', description: '用可视化平台训练一个鸢尾花分类模型，调参观察准确率变化。', difficulty: 3, type: '认知与决策', estimatedTime: '60分钟', score: 70, courseId: 5, courseName: '第5讲 机器自我成长进步：机器学习' },
  { id: 6, name: '设计一台服务机器人', description: '围绕校园导览场景，画出机器人的感知—决策—执行流程。', difficulty: 2, type: '具身智能', estimatedTime: '45分钟', score: 55, courseId: 6, courseName: '第6讲 未来生活离不开的伙伴：智能机器人' },
  { id: 7, name: '多智能体协作推演', description: '在仿真环境中为 3 个智能体设计协作策略并观察群体行为。', difficulty: 4, type: '具身智能', estimatedTime: '60分钟', score: 80, courseId: 7, courseName: '第7讲 机器世界不孤单：多智能体' },
  { id: 8, name: '搭建简易物理仿真', description: '用物理引擎模拟小球碰撞，理解仿真环境如何生成训练数据。', difficulty: 4, type: '具身智能', estimatedTime: '60分钟', score: 80, courseId: 8, courseName: '第8讲 机器生活的世界：物理世界仿真模拟' },
  { id: 9, name: '生成一段 AI 旋律', description: '用 AI 作曲工具生成 8 小节旋律，比较不同风格参数的效果。', difficulty: 2, type: '智能创作', estimatedTime: '40分钟', score: 50, courseId: 9, courseName: '第9讲 舞动科技的音符：人工智能音乐' },
  { id: 10, name: '我的 AI 学习计划', description: '结合十讲内容，制定一份面向自己的 AI 学习路线图。', difficulty: 1, type: '人工智能基础', estimatedTime: '30分钟', score: 40, courseId: 10, courseName: '第10讲 人工智能在北大' },
]

const buildPresentationAdminCourse = (course: PresentationCourseSeed, index: number): Course => ({
  id: course.id,
  name: course.name,
  description: course.description,
  cover: course.cover,
  difficulty: course.difficulty,
  category: course.category,
  status: 'published',
  studentCount: 48 + index * 3,
  experimentCount: PRESENTATION_MODULE_SEEDS.filter((module) => module.courseId === course.id).length,
  createTime: `2024-03-${String(index + 1).padStart(2, '0')} 10:00:00`,
})

const buildPresentationCourseSummary = (course: PresentationCourseSeed): CourseSummaryDto => ({
  id: course.id,
  name: course.name,
  description: course.description,
  difficulty: course.difficulty,
  imageUrl: course.cover.replace(/^\//, ''),
  type: course.type,
  tags: course.tags,
  status: 'published',
  estimatedHours: course.difficulty <= 2 ? 1 : 2,
})

const buildPresentationModuleOverview = (module: PresentationModuleSeed): ModuleOverViewType => ({
  id: module.id,
  name: module.name,
  description: module.description,
  difficulty: module.difficulty,
  type: module.type,
  status: 'available',
  estimatedTime: module.estimatedTime,
  score: module.score,
})

const buildPresentationAdminLab = (module: PresentationModuleSeed, index: number): Experiment => ({
  id: module.id,
  name: module.name,
  description: module.description,
  difficulty: module.difficulty,
  courseId: module.courseId,
  courseName: module.courseName,
  status: 'published',
  taskPoints: [
    {
      id: module.id * 10 + 1,
      name: `${module.name}任务点`,
      score: 50,
      description: `围绕 ${module.name} 的核心知识点展开训练`,
    },
  ],
  environment: {
    targetMachine: {
      image: `ai-task-${module.id}:latest`,
      port: 80,
      memory: module.difficulty >= 4 ? '2GB' : '1GB',
    },
    operationMachine: {
      image: 'ai-notebook:latest',
      port: 6080,
      memory: '2GB',
    },
  },
  studentCount: 32 + (index % 6) * 8,
  completionRate: 58 + (index % 5) * 6,
  averageScore: 70 + (index % 4) * 5,
  createTime: `2024-03-${String(index + 1).padStart(2, '0')} 09:00:00`,
})

export const buildPresentationCourseSummaries = (): CourseSummaryDto[] =>
  PRESENTATION_COURSE_SEEDS.map(buildPresentationCourseSummary)

export const buildPresentationAdminCourses = (): Course[] =>
  PRESENTATION_COURSE_SEEDS.map(buildPresentationAdminCourse)

export const buildPresentationUserCourses = (): CourseOverViewType[] =>
  PRESENTATION_COURSE_SEEDS.map((course, index) => ({
    id: course.id,
    name: course.name,
    image: course.cover,
    description: course.description,
    status: 'available',
    category: course.type,
    difficulty: course.difficulty,
    estimatedHours: 6 + (index % 5),
    tags: course.tags,
    totalStudents: 800 + index * 35,
    videoUrl: course.videoUrl,
  }))

export const buildPresentationModuleOverviews = (): ModuleOverViewType[] =>
  PRESENTATION_MODULE_SEEDS.map(buildPresentationModuleOverview)

export const buildPresentationAdminLabs = (): Experiment[] =>
  PRESENTATION_MODULE_SEEDS.map(buildPresentationAdminLab)

const courseSummaryMap = new Map(buildPresentationCourseSummaries().map((item) => [item.name, item]))
const adminCourseMap = new Map(buildPresentationAdminCourses().map((item) => [item.name, item]))
const moduleOverviewMap = new Map(buildPresentationModuleOverviews().map((item) => [item.name, item]))
const adminLabMap = new Map(buildPresentationAdminLabs().map((item) => [item.name, item]))

export const mergeCourseSummariesWithPresentation = (remoteCourses: CourseSummaryDto[] = []) =>
  PRESENTATION_COURSE_SEEDS.map((seed) => {
    const base = courseSummaryMap.get(seed.name)!
    const remote = remoteCourses.find((item) => item.name === seed.name)
    return remote
      ? {
          ...base,
          ...remote,
          description: remote.description || base.description,
          imageUrl: remote.imageUrl || base.imageUrl,
          type: remote.type || base.type,
          tags: remote.tags?.length ? remote.tags : base.tags,
        }
      : base
  })

export const mergeAdminCoursesWithPresentation = (remoteCourses: Course[] = []) =>
  PRESENTATION_COURSE_SEEDS.map((seed) => {
    const base = adminCourseMap.get(seed.name)!
    const remote = remoteCourses.find((item) => item.name === seed.name)
    return remote
      ? {
          ...base,
          ...remote,
          description: remote.description || base.description,
          cover: remote.cover || base.cover,
          category: remote.category || base.category,
          studentCount: remote.studentCount || base.studentCount,
          experimentCount: base.experimentCount,
          createTime: remote.createTime || base.createTime,
        }
      : base
  })

export const mergeModuleOverviewsWithPresentation = (remoteModules: ModuleOverViewType[] = []) =>
  PRESENTATION_MODULE_SEEDS.map((seed) => {
    const base = moduleOverviewMap.get(seed.name)!
    const remote = remoteModules.find((item) => item.name === seed.name)
    return remote
      ? {
          ...base,
          ...remote,
          description: remote.description || base.description,
          type: remote.type || base.type,
          estimatedTime: remote.estimatedTime || base.estimatedTime,
          score: remote.score || base.score,
        }
      : base
  })

export const mergeAdminLabsWithPresentation = (remoteLabs: Experiment[] = []) =>
  PRESENTATION_MODULE_SEEDS.map((seed) => {
    const base = adminLabMap.get(seed.name)!
    const remote = remoteLabs.find((item) => item.name === seed.name)
    return remote
      ? {
          ...base,
          ...remote,
          description: remote.description || base.description,
          courseId: remote.courseId ?? base.courseId,
          courseName: remote.courseName || base.courseName,
          taskPoints: remote.taskPoints?.length ? remote.taskPoints : base.taskPoints,
          environment: Object.keys(remote.environment || {}).length ? remote.environment : base.environment,
          studentCount: remote.studentCount || base.studentCount,
          completionRate: remote.completionRate || base.completionRate,
          averageScore: remote.averageScore || base.averageScore,
          createTime: remote.createTime || base.createTime,
        }
      : base
  })

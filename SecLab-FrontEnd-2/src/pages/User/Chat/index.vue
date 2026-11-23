<template>
  <div class="min-h-screen flex flex-col mt-16">
    <!-- 顶部装饰线 -->
    <div class="h-px bg-gradient-to-r from-transparent via-primary/20 to-transparent"></div>
    
    <div class="w-full mx-auto flex-grow flex flex-col px-0 py-0 sm:p-4">
      <div class="card bg-base-100 shadow-xl sm:border border-base-200 flex-grow flex flex-col h-[calc(100vh-2px)]">
        <div class="card-body p-0 flex flex-col flex-grow">
          <!-- 顶部栏 -->
          <div class="flex items-center justify-between p-4 border-b border-base-200 bg-base-100/90 backdrop-blur-sm sticky top-0 z-10">
            <div class="flex items-center gap-2">
              <div class="w-10 h-10 rounded-lg bg-gradient-to-br from-primary to-secondary flex items-center justify-center shadow-lg">
                <i class="fas fa-robot text-xl text-white"></i>
              </div>
              <div>
                <div class="flex items-center gap-1">
                  <h2 class="text-xl font-bold">立心 <span class="text-primary">LMS</span></h2>
                  <div class="badge badge-primary badge-sm">Beta</div>
                </div>
                <p class="text-xs text-base-content/60">AI 微课学习助手</p>
              </div>
            </div>
            <div class="flex gap-2">
              <div class="dropdown dropdown-end">
                <label tabindex="0" class="btn btn-sm btn-ghost">
                  <i class="fas fa-cog"></i>
                </label>
                <ul tabindex="0" class="dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-52">
                  <li>
                    <a @click="clearMessages">
                      <i class="fas fa-trash-alt mr-2"></i>清空对话
                    </a>
                  </li>
                  <li>
                    <a @click="toggleTheme">
                      <i class="fas fa-moon mr-2"></i>切换主题
                    </a>
                  </li>
                  <li>
                    <a @click="switchToFloatingMode">
                      <i class="fas fa-external-link-alt mr-2"></i>悬浮窗模式
                    </a>
                  </li>
                </ul>
              </div>
            </div>
          </div>
          
          <!-- 聊天消息区域 - 修复高度设置 -->
          <div ref="chatContainer" class="flex-grow overflow-y-auto p-2 sm:p-4 space-y-4 bg-base-200/30" style="height: calc(100vh - 13rem);">
            <div v-if="messages.length === 0" class="flex flex-col items-center justify-start h-full text-center text-base-content/50">
              <div class="w-20 h-20 sm:w-24 sm:h-24 rounded-full bg-gradient-to-br from-primary/20 to-secondary/20 
                          flex items-center justify-center mb-4 animate-pulse">
                <i class="fas fa-robot text-3xl sm:text-4xl text-primary"></i>
              </div>
              <h3 class="text-xl sm:text-2xl font-bold mb-2 bg-clip-text text-transparent 
                         bg-gradient-to-r from-primary via-secondary to-accent">
                立心 LMS AI 学习助手
              </h3>
              <div class="max-w-sm mt-2 text-base-content/70 px-4 text-sm sm:text-base">
                你的 AI 微课学习伙伴，陪你读懂人工智能十讲，解答课程疑问、辅助理解核心概念
              </div>
              
              <!-- 快速问题建议 - 改进响应式布局 -->
              <div class="mt-6 sm:mt-8 grid grid-cols-1 sm:grid-cols-2 gap-2 sm:gap-3 w-full max-w-2xl px-4">
                <button 
                  v-for="(suggestion, index) in suggestions" 
                  :key="index"
                  class="btn btn-outline btn-sm border-base-content/20 justify-start normal-case font-normal
                         hover:bg-primary/10 hover:border-primary/30 transition-all duration-300 text-xs sm:text-sm"
                  @click="askSuggestion(suggestion)"
                >
                  <i class="fas fa-question-circle text-primary/70 mr-2"></i>
                  {{ suggestion }}
                </button>
              </div>
            </div>
            
            <template v-else>
              <div
                v-for="(message, index) in messages"
                :key="index"
                class="mb-4 sm:mb-6" 
              >
                <!-- 用户消息 -->
                <div 
                  v-if="message.role === 'user'"
                  class="chat chat-end"
                >
                  <div class="chat-image avatar">
                    <div class="w-8 sm:w-10 rounded-full ring ring-primary ring-offset-base-100 ring-offset-2">
                      <img 
                        src="https://api.dicebear.com/7.x/avataaars/svg?seed=user"
                        alt="用户"
                      />
                    </div>
                  </div>
                  <div class="chat-bubble chat-bubble-primary">
                    {{ message.content }}
                  </div>
                  <div class="chat-footer opacity-50 flex gap-2 text-xs">
                    <span>{{ formatTime(message.timestamp) }}</span>
                  </div>
                </div>

                <!-- AI回复 -->
                <div 
                  v-else
                  class="chat chat-start"
                >
                  <div class="chat-image avatar">
                    <div class="w-8 sm:w-10 rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center shadow-md">
                      <i class="fas fa-robot text-xs sm:text-sm text-white"></i>
                    </div>
                  </div>
                  <div class="chat-bubble chat-bubble-neutral p-0">
                    <!-- 思考过程部分 - 可折叠面板 -->
                    <div v-if="message.thinking && message.showThinking" class="collapse collapse-arrow bg-base-200/30 mb-3 rounded-lg">
                      <input type="checkbox" class="min-h-0" checked /> 
                      <div class="collapse-title py-2 px-3 min-h-0 flex items-center gap-2 text-base-content/70 text-xs font-medium">
                        <i class="fas fa-brain text-secondary"></i>
                        <span>思考过程</span>
                      </div>
                      <div class="collapse-content px-3 sm:px-4 pt-0">
                        <div class="text-xs sm:text-sm text-base-content/70 thinking-content p-3 sm:p-4">
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
                    <div class="p-3 sm:p-4" v-if="message.content || message.streamContent">
                      <div v-if="message.isStreaming">
                        <MarkdownRenderer :content="message.streamContent || ''" />
                      </div>
                      <div v-else>
                        <MarkdownRenderer :content="message.content" />
                      </div>
                    </div>
                    <div v-else class="flex items-center gap-2 p-3 sm:p-4">
                      <span class="loading loading-dots loading-sm"></span>
                      <span>思考中...</span>
                    </div>
                  </div>
                  <div class="chat-footer opacity-50 flex gap-2 text-xs">
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
              <!-- 添加底部额外空间确保最后的消息可见 -->
              <div class="h-24 sm:h-32 md:h-40"></div>
            </template>
          </div>

          <!-- 输入区域 - 改进响应式设计 -->
          <div class="border-t border-base-200 p-3 pt-4 sm:p-4 bg-base-100 sticky bottom-0">
            <div class="flex flex-col gap-2">
              <div class="flex items-center gap-2 mb-2">
                <div class="flex items-center tooltip tooltip-right" data-tip="启用后，AI将展示推理思考过程">
                  <button
                    class="btn btn-sm btn-outline rounded-full gap-1 px-3 border-base-content/30"
                    :class="{'btn-primary': enableThinking, 'border-primary': enableThinking}"
                    @click="enableThinking = !enableThinking"
                  >
                    <i class="fas fa-brain text-xs"></i>
                    <span class="text-xs">深度思考</span>
                    <div class="badge badge-xs" :class="enableThinking ? 'badge-primary' : 'badge-ghost'"></div>
                  </button>
                </div>
                <div v-if="enableThinking" class="text-xs text-base-content/60">
                  已开启深度思考模式，AI将展示分析过程
                </div>
              </div>
              <div class="join w-full">
                <textarea
                  class="textarea textarea-bordered join-item flex-1 min-h-[60px] max-h-[120px] resize-none focus:outline-primary text-sm sm:text-base"
                  placeholder="输入你的问题，例如：什么是价值驱动？计算机视觉为什么难？..."
                  v-model="inputMessage"
                  @keydown.enter.ctrl="handleSendMessage"
                  ref="inputField"
                ></textarea>
              </div>
              <div class="flex justify-between items-center">
                <div class="text-xs text-base-content/60">
                  按Ctrl+Enter发送
                </div>
                <div class="flex items-center gap-2">
                  <button
                    class="btn btn-sm btn-ghost" 
                    @click="clearInput"
                    title="清空输入"
                  >
                    <i class="fas fa-eraser"></i>
                  </button>
                  <button
                    class="btn btn-sm sm:btn-md btn-primary"
                    @click="handleSendMessage"
                    :disabled="isLoading || !inputMessage.trim()"
                  >
                    <i class="fas fa-paper-plane mr-2"></i>
                    发送
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- 底部装饰线 -->
    <div class="h-px bg-gradient-to-r from-transparent via-primary/20 to-transparent"></div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, nextTick, watch } from 'vue'
import DOMPurify from 'dompurify'
import OpenAI from 'openai'
import MarkdownRenderer from '../../../components/MarkdownRenderer.vue'

interface Message {
  role: 'user' | 'assistant'
  content: string
  timestamp: Date
  thinking?: string
  streamContent?: string
  isStreaming?: boolean
  showThinking?: boolean  // 添加标记，指示这条消息是否要显示思考过程
}

// OpenAI客户端实例
const openai = new OpenAI({
  apiKey: import.meta.env.VITE_OPENAI_API_KEY || '', // 从环境变量获取API密钥
  dangerouslyAllowBrowser: true, // 允许在浏览器中使用（仅开发环境）
  baseURL:import.meta.env.VITE_BASE_URL || ''
})

const messages = ref<Message[]>([])
const inputMessage = ref('')
const isLoading = ref(false)
const chatContainer = ref<HTMLElement | null>(null)
const inputField = ref<HTMLTextAreaElement | null>(null)
const enableThinking = ref(false)
const showThinking = ref(false)

// 添加平台相关的背景信息
const platformInfo = {
  name: "立心之约 · 中学生人工智能微课",
  description: "由北京大学与北京通用人工智能研究院联合出品、朱松纯教授领衔打造的面向中学生的人工智能微课系列，共十讲。课程以「给机器立心」为主线，从人工智能的现状趋势出发，依次走进计算机视觉、自然语言处理、认知推理、机器学习、智能机器人、多智能体、物理世界仿真模拟、人工智能音乐，最终回到人工智能在北大，引导高中生认识 AI、理解 AI、学会与 AI 共处。",
  features: [
    "十讲体系：涵盖 AI 总纲、计算机视觉、自然语言处理、认知推理、机器学习等主题",
    "价值驱动：以「给机器立心」为主线，理解人工智能的价值与方向",
    "乌鸦与鹦鹉：用生动故事辨析智能的本质与层次",
    "面向高中生：语言通俗、案例丰富、循序渐进",
    "名校出品：北京大学与北京通用人工智能研究院联合打造",
    "互动练习：每讲配有思考题与知识点小测",
    "积分与排行：记录学习成果，激励持续探索",
    "深度思考功能，展示AI分析过程",
    "学习进度跟踪，自适应学习路径推荐"
  ],
  courses: [
    {name: "第一讲 人工智能的现状趋势与战略（总纲）", topics: ["给机器立心", "价值驱动", "乌鸦与鹦鹉", "AI 发展脉络"]},
    {name: "第二讲 机器眼中的大千世界：计算机视觉", topics: ["图像识别", "卷积神经网络", "视觉理解的难点"]},
    {name: "第三讲 语言与机器的火花碰撞：自然语言处理", topics: ["词向量", "语言模型", "机器翻译"]},
    {name: "第四讲 认知科学与AI世界的邀约：认知推理", topics: ["知识表示", "常识推理", "因果关系"]},
    {name: "第五讲 机器自我成长进步：机器学习", topics: ["监督学习", "过拟合", "神经网络"]},
    {name: "第六讲 未来生活离不开的伙伴：智能机器人", topics: ["感知与行动", "运动控制", "人机协作"]},
    {name: "第七讲 机器世界不孤单：多智能体", topics: ["合作与竞争", "博弈", "群体智能"]},
    {name: "第八讲 机器生活的世界：物理世界仿真模拟", topics: ["仿真环境", "物理引擎", "虚实结合"]},
    {name: "第九讲 舞动科技的音符：人工智能音乐", topics: ["音乐生成", "算法作曲", "AI 与艺术"]},
    {name: "第十讲 人工智能在北大", topics: ["北大 AI 学科", "科研与人才培养", "人工智能通识教育"]}
  ],
  experimentModules: [
    {id: 1, name: "给机器立心与价值驱动", type: "总纲与战略", difficulty: 2},
    {id: 2, name: "乌鸦与鹦鹉：智能的本质", type: "总纲与战略", difficulty: 3},
    {id: 3, name: "图像识别与卷积神经网络", type: "感知与语言", difficulty: 3},
    {id: 4, name: "计算机视觉为什么难", type: "感知与语言", difficulty: 4},
    {id: 5, name: "词向量与语言模型", type: "感知与语言", difficulty: 3},
    {id: 6, name: "知识表示与常识推理", type: "认知与学习", difficulty: 4},
    {id: 7, name: "监督学习与过拟合", type: "认知与学习", difficulty: 3},
    {id: 8, name: "神经网络与深度学习", type: "认知与学习", difficulty: 4},
    {id: 9, name: "智能机器人的感知与行动", type: "智能体与机器人", difficulty: 3},
    {id: 10, name: "多智能体合作与竞争", type: "智能体与机器人", difficulty: 4},
    {id: 11, name: "物理世界仿真模拟", type: "智能体与机器人", difficulty: 4},
    {id: 12, name: "算法作曲与音乐生成", type: "AI 与人文", difficulty: 3},
    {id: 13, name: "人工智能在北大", type: "AI 与人文", difficulty: 2}
  ],
  scoreboard: {
    description: "平台排行榜根据学生的学习进度、微课完成度和获得的积分进行排名",
    rankingFactors: [
      "总积分：完成微课学习和答题获得的积分总和",
      "完成讲数：已学完的微课讲数",
      "答题正确率：知识点小测的正确率",
      "学习活跃度：连续学习与互动情况",
      "创新性：对开放性思考题的独特见解可获得额外加分"
    ],
    timeRanges: ["周排行", "月排行", "总排行"],
    filters: ["年级", "班级", "时间范围"]
  },
  learningEnv: {
    description: "平台提供两种主要学习资源：微课视频与互动练习",
    operationEnv: "微课视频与讲义，帮助学生理解每一讲的核心概念与案例",
    targetEnv: "互动练习题与思考题，帮助学生巩固知识、检验理解"
  },
  questionTypes: [
    "选择题：测试对人工智能基础概念的理解",
    "开放题：引导学生结合生活阐述对 AI 的看法",
    "思考题：围绕「给机器立心」等主题展开思辨"
  ],
  learningPath: "学习路径从第一讲总纲开始，先理解人工智能的现状趋势与「给机器立心、价值驱动」的核心思想，再依次学习计算机视觉、自然语言处理、认知推理、机器学习等技术主题，进而了解智能机器人、多智能体与物理世界仿真，最后通过人工智能音乐与北大 AI 故事感受 AI 与人文的交融。建议按讲次顺序循序渐进。"
}

// 监听enableThinking变化，同步更新showThinking
watch(enableThinking, (newValue) => {
  showThinking.value = newValue
})

// 快速问题建议
const suggestions = [
  "什么是「给机器立心」？",
  "价值驱动是什么意思？",
  "计算机视觉为什么难？",
  "词向量有什么用？",
  "什么是过拟合？",
  "乌鸦和鹦鹉有什么区别？"
]

// 使用建议问题
const askSuggestion = (question: string) => {
  inputMessage.value = question
  handleSendMessage()
}

// 格式化时间
const formatTime = (date: Date) => {
  return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}

// 格式化消息内容，支持markdown - 这个方法可以保留但不再使用
const formatMessageContent = (content: string) => {
  return content
}

// 复制到剪贴板
const copyToClipboard = (text: string) => {
  navigator.clipboard.writeText(text)
    .then(() => {
      // 可以添加toast通知用户复制成功
      console.log('复制成功')
    })
    .catch(err => {
      console.error('复制失败:', err)
    })
}

// 清空消息
const clearMessages = () => {
  if (messages.value.length > 0 && confirm('确定要清空所有对话记录吗？')) {
    messages.value = []
  }
}

// 清空输入
const clearInput = () => {
  inputMessage.value = ''
  inputField.value?.focus()
}

// 切换主题
const toggleTheme = () => {
  const html = document.querySelector('html')
  if (html) {
    const currentTheme = html.getAttribute('data-theme')
    html.setAttribute('data-theme', currentTheme === 'night' ? 'light' : 'night')
  }
}

// 切换到悬浮窗模式
const switchToFloatingMode = () => {
  // 将当前消息存储到本地存储，以便悬浮窗可以加载
  localStorage.setItem('chatMessages', JSON.stringify(messages.value))
  // 导航到悬浮窗演示页面
  window.location.href = '#/user/floating-chat-demo'
}

// 滚动到底部
const scrollToBottom = () => {
  if (chatContainer.value) {
    // 使用更长的延时确保DOM完全更新
    setTimeout(() => {
      if (chatContainer.value) {
        chatContainer.value.scrollTop = chatContainer.value.scrollHeight + 200
      }
    }, 100)
  }
}

// 检测用户问题是否与平台相关
const isPlatformRelatedQuestion = (question: string): boolean => {
  const platformKeywords = [
    "平台", "立心之约", "AI 微课", "微课", "课程", "讲", "学习路径", "学习", "讲座",
    "怎么使用", "如何开始", "功能", "特点", "课程内容", "学习计划",
    "AI", "人工智能", "价值驱动", "给机器立心", "乌鸦", "鹦鹉", "计算机视觉",
    "自然语言处理", "认知推理", "机器学习", "智能机器人", "多智能体", "仿真",
    "人工智能音乐", "北大", "过拟合", "词向量", "神经网络", "积分", "排名",
    "排行榜", "答题", "小测", "年级", "班级", "学时", "难度", "思考题", "教师",
    "分数", "学习进度", "证书", "成绩", "练习"
  ]
  
  // 转换为小写进行匹配
  const lowercaseQuestion = question.toLowerCase()
  return platformKeywords.some(keyword => 
    lowercaseQuestion.includes(keyword.toLowerCase())
  )
}

// 增强用户问题，添加平台相关上下文
const enhanceUserQuestion = (question: string): string => {
  if (!isPlatformRelatedQuestion(question)) {
    // 如果不是平台相关问题，保持原样
    return question
  }
  
  // 为平台相关问题添加上下文
  let enhancedPrompt = `关于立心之约 AI 微课的问题：${question}\n\n请根据以下课程信息回答：\n`;
  
  // 检查是否包含特定关键词，有针对性地添加相关上下文
  const lowerQuestion = question.toLowerCase();
  
  // 添加课程相关信息
  if (lowerQuestion.includes("课程") || lowerQuestion.includes("学习")) {
    enhancedPrompt += "【课程内容】\n";
    platformInfo.courses.forEach(course => {
      enhancedPrompt += `- ${course.name}：${course.topics.join("、")}\n`;
    });
    enhancedPrompt += "\n";
  }
  
  // 添加知识模块相关信息
  if (lowerQuestion.includes("知识") || lowerQuestion.includes("模块") || 
      lowerQuestion.includes("练习") || lowerQuestion.includes("视觉") || 
      lowerQuestion.includes("语言") || lowerQuestion.includes("学习") ||
      lowerQuestion.includes("智能")) {
    enhancedPrompt += "【知识模块】\n课程共十讲，包含以下核心知识模块：\n";
    const modules = platformInfo.experimentModules.map(m => `${m.name}(难度:${m.difficulty}星)`);
    // 根据类型分组
    const moduleTypes = [...new Set(platformInfo.experimentModules.map(m => m.type))];
    moduleTypes.forEach(type => {
      enhancedPrompt += `- ${type}方向：${platformInfo.experimentModules
        .filter(m => m.type === type)
        .map(m => m.name)
        .join("、")}\n`;
    });
    enhancedPrompt += "\n";
  }
  
  // 添加排行榜相关信息
  if (lowerQuestion.includes("排行") || lowerQuestion.includes("排名") || 
      lowerQuestion.includes("积分") || lowerQuestion.includes("分数") || 
      lowerQuestion.includes("成绩") || lowerQuestion.includes("总分")) {
    enhancedPrompt += "【排名系统】\n";
    enhancedPrompt += `${platformInfo.scoreboard.description}\n`;
    enhancedPrompt += "排名依据：\n";
    enhancedPrompt += "- 排行榜主要根据学生的学习积分进行排名，积分越高排名越靠前\n";
    enhancedPrompt += "- 积分来源于完成微课学习与答题，完成度越高获得的积分越多\n";
    enhancedPrompt += "- 可按年级、班级和时间范围筛选排行榜\n";
    enhancedPrompt += "\n";
  }
  
  // 添加学习资源相关信息
  if (lowerQuestion.includes("资源") || lowerQuestion.includes("视频") || 
      lowerQuestion.includes("讲义") || lowerQuestion.includes("练习")) {
    enhancedPrompt += "【学习资源】\n";
    enhancedPrompt += `${platformInfo.learningEnv.description}\n`;
    enhancedPrompt += `- 微课视频与讲义：${platformInfo.learningEnv.operationEnv}\n`;
    enhancedPrompt += `- 互动练习：${platformInfo.learningEnv.targetEnv}\n\n`;
  }
  
  // 如果没有匹配到特定类别，添加课程概览
  if (!enhancedPrompt.includes("【")) {
    enhancedPrompt += "【课程概览】\n";
    enhancedPrompt += `${platformInfo.description}\n\n`;
    enhancedPrompt += "课程特色：\n";
    platformInfo.features.slice(0, 5).forEach(feature => {
      enhancedPrompt += `- ${feature}\n`;
    });
    enhancedPrompt += "\n";
  }
  
  return enhancedPrompt;
}

// 构建更详细的系统提示词
const getSystemPrompt = (): string => {
  return `你是「立心之约 · 中学生人工智能微课」（${platformInfo.name}）的AI学习助手，面向高中生，专注于人工智能通识教育与课程内容讲解。

课程信息：
${platformInfo.description}

课程特色：
${platformInfo.features.map(f => "- " + f).join("\n")}

十讲课程内容：
${platformInfo.courses.map(c => `- ${c.name}：${c.topics.join("、")}`).join("\n")}

核心知识模块：
课程共十讲，涵盖总纲与战略、感知与语言、认知与学习、智能体与机器人、AI 与人文五大方向。
难度从1星(入门)到5星(进阶)不等，每个模块包含核心概念、典型案例与思考题。
完成微课学习与答题后可获得相应积分。

排行榜系统：
${platformInfo.scoreboard.description}
排名主要根据学生的学习积分进行排名，积分高的学生排名靠前。积分通过完成微课学习与答题获得。
支持按${platformInfo.scoreboard.timeRanges.join("、")}查看排名，可按${platformInfo.scoreboard.filters.join("、")}进行筛选。

学习资源：
${platformInfo.learningEnv.description}
- 微课视频与讲义：${platformInfo.learningEnv.operationEnv}
- 互动练习：${platformInfo.learningEnv.targetEnv}

题目类型：
${platformInfo.questionTypes.join("\n")}

学习路径：
${platformInfo.learningPath}

你的角色：
1. 用高中生能听懂的语言，通俗讲解人工智能的核心概念与原理
2. 围绕「给机器立心、价值驱动」这条主线，帮助学生理解 AI 的价值与方向
3. 推荐合适的学习路径和微课讲次
4. 解答学习过程中遇到的问题，善于用乌鸦与鹦鹉等故事化案例辅助说明
5. 帮助学生理解计算机视觉、自然语言处理、认知推理、机器学习等技术主题
6. 解释平台积分和排名规则

回答规则：
- 当用户询问课程相关问题时，基于上述课程信息提供具体、准确的回答
- 当用户询问人工智能知识时，用生动、清晰、易懂的方式解释，避免堆砌术语
- 如不确定，请诚实地表明不知道，避免提供错误信息
- 回答应使用亲切且鼓励的语气，尽量简洁明了
- 优先推荐课程中的相关讲次和学习资源
- 根据问题自然地引用相关知识模块，鼓励学生按讲次循序渐进学习`
}

// 调用OpenAI API
const callOpenAI = async (userQuestion: string, messageIndex: number) => {
  if (!openai.apiKey) {
    messages.value[messageIndex].content = '错误：未配置API密钥，请联系管理员设置VITE_OPENAI_API_KEY环境变量。'
    return
  }

  messages.value[messageIndex].isStreaming = true
  messages.value[messageIndex].streamContent = ''
  
  // 初始化思考过程流内容并记录消息的思考显示状态
  messages.value[messageIndex].showThinking = enableThinking.value
  if (enableThinking.value) {
    messages.value[messageIndex].thinking = ''
  }
  
  try {
    // 构建消息历史
    const messageHistory = messages.value
      .slice(0, messageIndex)
      .map(msg => {
        if (msg.role === 'user') {
          // 向用户消息添加平台相关上下文
          return {
            role: msg.role,
            content: isPlatformRelatedQuestion(msg.content) ? enhanceUserQuestion(msg.content) : msg.content
          }
        }
        return {
          role: msg.role,
          content: msg.content
        }
      })
    
    // 添加增强的系统消息
    messageHistory.unshift({
      role: 'system',
      content: getSystemPrompt()
    } as any)

    // 构建请求参数
    const requestParams: any = {
      model: enableThinking.value ? 'deepseek-reasoner' : 'deepseek-chat',
      messages: messageHistory,
      temperature: 0.7,
      stream: true,
    }
    
    // 使用OpenAI SDK的流式API
    const stream = await openai.chat.completions.create(requestParams)

    let completeResponse = ''
    let completeThinking = ''
    
    // 处理流式响应
    for await (const chunk of stream) {
      // 处理普通内容
      const content = chunk.choices[0]?.delta?.content || ''
      if (content) {
        completeResponse += content
        messages.value[messageIndex].streamContent = completeResponse
        // 在每次更新内容后都滚动到底部
        nextTick(() => {
          scrollToBottom()
        })
      }
      
      // 处理思考过程
      if (enableThinking.value) {
        const reasoningContent = chunk.choices[0]?.delta?.reasoning_content || ''
        if (reasoningContent) {
          completeThinking += reasoningContent
          messages.value[messageIndex].thinking = completeThinking
        }
      }
    }
    
    // 更新最终完整回答
    messages.value[messageIndex].content = completeResponse
    messages.value[messageIndex].isStreaming = false
    
    
  } catch (error: any) {
    messages.value[messageIndex].streamContent = ''
    messages.value[messageIndex].content = `调用API时出错: ${error.message || '未知错误'}`
    messages.value[messageIndex].isStreaming = false
  }
}

// 发送消息
const handleSendMessage = () => {
  if (!inputMessage.value.trim() || isLoading.value) return

  // 在消息界面显示原始用户输入
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
    timestamp: new Date()
  })
  
  // 确保滚动到底部
  scrollToBottom()
  // 再次确保滚动到底部（解决某些浏览器渲染延迟问题）
  setTimeout(scrollToBottom, 100)
  setTimeout(scrollToBottom, 300)
  
  // 调用OpenAI API - 传入原始问题，增强会在API调用中进行
  callOpenAI(userQuestion, responseIndex)
    .finally(() => {
      isLoading.value = false
      // 回答完成后再次滚动到底部
      scrollToBottom()
      setTimeout(scrollToBottom, 100)
    })
}

// 优化监听消息变化的滚动处理
watch(messages, () => {
  // 使用nextTick确保DOM更新后再滚动
  nextTick(() => {
    scrollToBottom()
    // 再次滚动，确保内容完全可见
    setTimeout(() => {
      scrollToBottom()
    }, 200)
  })
}, { deep: true })

// 组件挂载后，聚焦输入框
onMounted(() => {
  inputField.value?.focus()
  // 确保聊天记录显示在底部
  nextTick(() => {
    scrollToBottom()
  })
})
</script>

<style scoped>
:deep(.chat-bubble) {
  max-width: 80%; /* 修改气泡最大宽度 */
  word-break: break-word;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1); /* 添加轻微阴影 */
}

:deep(.chat-bubble a) {
  color: var(--p);
  text-decoration: underline;
}

:deep(.chat-bubble pre) {
  background-color: hsl(var(--n) / 0.1);
  padding: 0.75rem;
  border-radius: 0.5rem;
  overflow-x: auto;
  margin: 0.5rem 0;
}

:deep(.chat-bubble code) {
  background-color: hsl(var(--n) / 0.1);
  padding: 0.2rem 0.4rem;
  border-radius: 0.25rem;
  font-size: 0.9em;

}


:deep(.chat-bubble ul, .chat-bubble ol) {
  padding-left: 1.5rem;
  margin: 0.5rem 0;
}

:deep(.chat-bubble ul) {
  list-style-type: disc;
}

:deep(.chat-bubble ol) {
  list-style-type: decimal;
}

/* 机器人图标居中样式 */
.avatar .rounded-full {
  display: flex !important;
  align-items: center !important;
  justify-content: center !important;
}

.avatar .fas.fa-robot, .avatar .fas.fa-brain {
  display: block;
  line-height: 1;
  margin: 0;
  padding: 0;
}

/* 思考过程样式 */
.collapse-arrow .collapse-title:after {
  top: 1.2rem;
  right: 1rem;
}

.thinking-content :deep(p) {
  margin-bottom: 0.5rem;
}

.thinking-content :deep(ol), .thinking-content :deep(ul) {
  margin-top: 0.25rem;
  margin-bottom: 0.5rem;
}

/* 确保折叠面板内部内容缩进和样式正确 */
.collapse-content {
  padding-bottom: 0.5rem;
}

.collapse .collapse-title {
  padding-top: 0.5rem;
  padding-bottom: 0.5rem;
}

/* 确保聊天区域和输入区域没有重叠 */
.chat-start:last-child,
.chat-end:last-child {
  margin-bottom: 1rem;
}

/* 确保气泡底部内容可见 */
.chat-bubble {
  margin-bottom: 0.25rem;
}

/* 添加响应式布局样式 */
@media (max-width: 640px) {
  :deep(.chat-bubble) {
    max-width: 88%;
  }
  
  .card {
    margin: 0;
    border-radius: 0;
    box-shadow: none;
  }
  
  :deep(.markdown-body) {
    font-size: 0.9rem;
  }
  
  /* 修复移动端底部内边距 */
  .chat-start:last-child,
  .chat-end:last-child {
    margin-bottom: 0.75rem;
  }
}
</style> 

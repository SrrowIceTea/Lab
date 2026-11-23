<template>
  <div class="min-h-screen flex flex-col mt-16">
    <!-- 页面内容 -->
    <div class="w-full mx-auto flex-grow flex flex-col px-4 py-8">
      <div class="card bg-base-100 shadow-xl border border-base-200 max-w-4xl mx-auto w-full">
        <div class="card-body">
          <h2 class="card-title text-2xl font-bold mb-4">悬浮聊天窗页面</h2>
          
          <div class="mb-8">
            <p class="mb-4">这个页面展示了如何在其他页面中使用悬浮聊天窗组件。用户可以在浏览其他内容的同时，随时与AI助手进行交流。</p>
            
            <div class="alert alert-info mb-4">
              <i class="fas fa-info-circle mr-2"></i>
              <span>悬浮窗可以拖动到屏幕的任意位置，也可以最小化、最大化或关闭。</span>
            </div>
            
            <div class="flex gap-4 flex-wrap">
              <button 
                @click="toggleChatVisibility" 
                class="btn btn-primary"
              >
                <i class="fas fa-comment-alt mr-2"></i>
                {{ isChatVisible ? '隐藏聊天窗' : '显示聊天窗' }}
              </button>
              
              <button 
                @click="resetChatPosition" 
                class="btn btn-outline"
              >
                <i class="fas fa-undo mr-2"></i>
                重置位置
              </button>
            </div>
          </div>
          
          <div class="divider">页面内容示例</div>
          
          <!-- 示例内容 -->
          <div class="prose max-w-none">
            <h3>人工智能微课学习路径</h3>
            <p>人工智能是一个广阔的领域，包含多个有趣的方向。以下是「立心之约」微课十讲的学习路径：</p>
            
            <ul>
              <li><strong>总纲与战略</strong> - 给机器立心、价值驱动，以及乌鸦与鹦鹉的故事</li>
              <li><strong>计算机视觉</strong> - 机器如何「看」懂大千世界，图像识别为何困难</li>
              <li><strong>自然语言处理</strong> - 词向量、语言模型，让机器理解人类语言</li>
              <li><strong>认知推理</strong> - 知识表示、常识推理，走进认知科学</li>
              <li><strong>机器学习</strong> - 监督学习、过拟合，机器如何自我成长</li>
              <li><strong>智能机器人</strong> - 感知与行动，未来生活的伙伴</li>
              <li><strong>多智能体</strong> - 合作与竞争，机器世界并不孤单</li>
              <li><strong>物理世界仿真模拟</strong> - 在虚拟世界里理解真实物理规律</li>
              <li><strong>人工智能音乐</strong> - 算法作曲，感受科技与艺术的交融</li>
              <li><strong>人工智能在北大</strong> - 走近北大的 AI 学科与人才培养</li>
            </ul>
            
            <p>无论你对哪个方向感兴趣，建议从第一讲总纲开始，循序渐进地学完十讲。可以随时通过悬浮聊天窗口向 AI 助手询问更详细的学习建议！</p>

            <h3>学习建议</h3>
            <p>以下是一些学习方法建议，可以帮助你更好地掌握课程内容：</p>
            
            <ol>
              <li>每听一讲，先用自己的话复述核心概念</li>
              <li>围绕「给机器立心」写下自己的理解与思考</li>
              <li>尝试用生活中的例子解释词向量或过拟合</li>
              <li>和同学讨论乌鸦与鹦鹉故事背后的智能观</li>
              <li>通过悬浮窗向 AI 助手追问感兴趣的讲次</li>
            </ol>
            
            <p>如果你对任何讲次感兴趣，可以点击右下角的聊天图标，向 AI 助手询问更多详细信息。</p>
          </div>
        </div>
      </div>
    </div>
    
    <!-- 悬浮聊天窗组件 -->
    <FloatingChat 
      v-if="isChatVisible" 
      :initial-position="chatPosition"
      @close="isChatVisible = false" 
    />
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import FloatingChat from '../../../components/FloatingChat.vue'

// 控制聊天窗口的显示状态
const isChatVisible = ref(true)
const chatPosition = ref({ x: 20, y: 20 })

// 切换聊天窗口显示状态
const toggleChatVisibility = () => {
  isChatVisible.value = !isChatVisible.value
}

// 重置聊天窗口位置
const resetChatPosition = () => {
  chatPosition.value = { x: 20, y: 20 }
}
</script>

<style scoped>
.divider {
  margin: 2rem 0;
}
</style> 

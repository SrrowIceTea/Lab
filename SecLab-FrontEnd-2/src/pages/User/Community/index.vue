<script setup lang="ts">
import { ref, onMounted } from 'vue';

// 帖子类型定义
interface Post {
  id: number;
  title: string;
  content: string;
  author: {
    id: number;
    name: string;
    avatar: string;
  };
  createdAt: string;
  likes: number;
  comments: Comment[];
  tags: string[];
}

// 评论类型定义
interface Comment {
  id: number;
  content: string;
  author: {
    id: number;
    name: string;
    avatar: string;
  };
  createdAt: string;
  likes: number;
}

// 模拟帖子数据
const posts = ref<Post[]>([
  {
    id: 1,
    title: "我用图像分类模型识别校园植物的记录",
    content: "这周在「立心之约」AI 微课上做了个小项目：用迁移学习训练图像分类模型，识别校园里常见的植物。分享下我的步骤：\n\n1. 用手机拍了 5 类植物，每类大约 80 张照片\n2. 基于预训练的 MobileNet 做微调，只训练最后几层\n3. 用旋转、翻转、裁剪做数据增强，扩充训练集\n\n最后在测试集上准确率到了 92%，最容易被认错的是两种外形相似的阔叶植物。最大的体会是：数据质量往往比模型大小更重要，拍照时尽量保证光线和角度一致。\n\n代码和数据集都整理好了，欢迎交流！",
    author: {
      id: 1,
      name: "王伟雪",
      avatar: "/student1.jpg"
    },
    createdAt: "2024-03-15T08:30:00",
    likes: 42,
    tags: ["图像分类", "迁移学习", "校园植物", "学习记录"],
    comments: [
      {
        id: 1001,
        content: "这个选题很贴近生活！请问用的是哪种预训练模型？我在做手写数字识别时，数据增强后准确率反而下降，还在找原因。",
        author: {
          id: 2,
          name: "李强",
          avatar: "/student3.jpg"
        },
        createdAt: "2024-03-15T09:45:00",
        likes: 8
      },
      {
        id: 1002,
        content: "补充一点，类别不均衡的话可以给样本少的类别加一点权重，我上次这样做后小类别的召回率明显提升了。",
        author: {
          id: 3,
          name: "林宗恒",
          avatar: "/example.png"
        },
        createdAt: "2024-03-15T10:20:00",
        likes: 15
      }
    ]
  },
  {
    id: 2,
    title: "训练分类器时遇到过拟合怎么办？求支招",
    content: "最近在做一个文本情感分类的练习，训练集准确率能到 98%，但验证集一直卡在 75% 左右，典型的过拟合。我试过的办法：\n\n1. 加了 dropout 层，从 0.3 调到 0.5\n2. 做了 L2 正则化\n3. 尽量增加训练数据\n\n效果有改善但不明显。想请教大家：\n- early stopping 一般怎么设置 patience？\n- 是不是模型太复杂了，需要换更小的网络？\n- 有没有判断「该停了」的经验指标？\n\n贴了训练曲线图，欢迎指教。",
    author: {
      id: 2,
      name: "李强",
      avatar: "/student3.jpg"
    },
    createdAt: "2024-03-14T14:20:00",
    likes: 37,
    tags: ["过拟合", "模型调优", "深度学习", "答疑"],
    comments: [
      {
        id: 1003,
        content: "这个我也遇到过。补充一点，如果数据实在不够，可以试试回译、同义词替换这些数据增强方法，或者用预训练模型做特征提取，往往比硬堆网络层数更有效。",
        author: {
          id: 4,
          name: "张明",
          avatar: "/student4.jpg"
        },
        createdAt: "2024-03-14T15:10:00",
        likes: 12
      }
    ]
  },
  {
    id: 3,
    title: "AI 续写贝多芬第十交响曲听后感",
    content: "音乐课上听了一段用 AI 续写的贝多芬《第十交响曲》片段，感触挺深，记录下来和大家分享：\n\n1. 旋律的前半段很接近贝多芬的风格，铜管的使用很有气势\n2. 但到了发展部，主题动机重复得有点多，缺少那种层层推进的张力\n3. 最打动我的反而是 AI 生成的一段安静的弦乐过渡\n\n我的感受是：AI 能学到「风格的表象」，但那种来自生命体验的情感冲击，目前还很难真正复制。它更像是一个能随时陪你头脑风暴的搭档。\n\n大家怎么看？有没有听过类似的 AI 音乐作品，推荐一下。",
    author: {
      id: 5,
      name: "赵明",
      avatar: "/student5.jpg"
    },
    createdAt: "2024-03-13T18:45:00",
    likes: 56,
    tags: ["AI音乐", "听后感", "艺术与科技", "生成式AI"],
    comments: [
      {
        id: 1004,
        content: "同感！AI 学到的更像是统计规律，真正打动人的往往是「不完美」里藏着的情感。不过作为启发灵感的工具已经很棒了。",
        author: {
          id: 6,
          name: "陈静",
          avatar: "/student2.jpg"
        },
        createdAt: "2024-03-13T19:20:00",
        likes: 8
      }
    ]
  },
  {
    id: 4,
    title: "多智能体协作推演心得：让三个 AI 一起解题",
    content: "在「立心之约」的拓展任务里，我试着让三个不同角色的 AI 智能体协作解一道数学建模题，记录一下心得：\n\n1. 一个负责审题和拆解任务\n2. 一个负责具体计算和推导\n3. 一个负责检查和质疑结论\n\n整体效果比单个 AI 直接给答案好很多，尤其是「质疑者」这个角色，真的能发现前两个推理中的破绽。但问题也挺明显：\n- 智能体之间有时会互相「附和」，形成回音室\n- 对话轮数一多，最初的约束就被渐渐遗忘了\n\n我的办法是每一轮都把任务目标重新强调一遍。大家有更好的协作范式推荐吗？",
    author: {
      id: 7,
      name: "刘洋",
      avatar: "/student6.png"
    },
    createdAt: "2024-03-12T10:30:00",
    likes: 45,
    tags: ["多智能体", "协作推演", "提示词", "学习心得"],
    comments: [
      {
        id: 1005,
        content: "「质疑者」这个角色设计得很妙！我也试过，给它明确的审查清单效果会更好，比如让它逐条核对数据来源和假设是否成立。",
        author: {
          id: 8,
          name: "周杰",
          avatar: "/student10.png"
        },
        createdAt: "2024-03-12T11:15:00",
        likes: 12
      }
    ]
  },
  {
    id: 5,
    title: "用 AI 辅助整理学习笔记一个月的心得",
    content: "坚持用 AI 助手辅助整理各科笔记一个月了，分享下我的完整流程：\n\n1. 课前预习：\n- 把教材章节丢给 AI，让它生成知识框架\n- 标出我不理解的概念\n\n2. 课中记录：\n- 随手记下关键词和疑问\n- 让 AI 帮我补齐逻辑、补充例子\n\n3. 课后复习：\n- 用 AI 生成练习题自测\n- 我错过的题让它换个角度再讲一遍\n\n4. 一点体会：\n- AI 讲得很流畅，但偶尔会出错，关键结论一定要回到课本核对\n- 把它当成「随时能问的同学」，而不是「标准答案」\n\n需要我整理提示词模板的同学可以留言。",
    author: {
      id: 9,
      name: "吴超",
      avatar:"/student9.png"
    },
    createdAt: "2024-03-11T16:20:00",
    likes: 89,
    tags: ["AI助手", "学习笔记", "学习方法", "心得体会"],
    comments: [
      {
        id: 1006,
        content: "流程很清晰！建议补充一下「如何让 AI 提问而不是直接给答案」，我最近在试苏格拉底式提问，效果不错。",
        author: {
          id: 10,
          name: "孙伟",
          avatar:"/student8.png"
        },
        createdAt: "2024-03-11T17:00:00",
        likes: 23
      }
    ]
  },
  {
    id: 6,
    title: "提示词工程入门：让 AI 更懂你的问题",
    content: "分享几个这学期总结的提示词小技巧，对写作业和做项目都很实用：\n\n1. 给角色：「你是一位耐心的物理老师」\n2. 给背景：说明你的年级和知识水平\n3. 给格式：要求分点、表格或代码块输出\n4. 给例子：一两句展示你想要的答案风格\n5. 给反馈：不满意就具体说哪里不对，让它改\n\n同样是问「解释相对论」，加了角色和背景之后的回答，可读性完全不一样。\n\n关键是把 AI 当成一个很聪明但不了解你的新同学，你把信息给得越清楚，它帮得越多。",
    author: {
      id: 11,
      name: "赵明",
      avatar:"/student5.jpg"
    },
    createdAt: "2024-03-10T09:15:00",
    likes: 76,
    tags: ["提示词工程", "AI应用", "学习方法", "入门"],
    comments: [
      {
        id: 1007,
        content: "「给例子」这点特别赞同，也就是 few-shot 提示。有时候一两个示例比一大段描述都管用。",
        author: {
          id: 12,
          name: "陈静",
          avatar: "/student2.jpg"
        },
        createdAt: "2024-03-10T10:30:00",
        likes: 18
      }
    ]
  },
  {
    id: 7,
    title: "用 AI 做班级科技节海报，踩过的坑",
    content: "这次科技节我们尝试用 AI 生成主题海报，记录下踩过的坑，供同样想用的同学参考：\n\n1. 第一次生成：画面很美，但上面的文字全是乱码\n2. 后来改成：AI 只生成背景图案，文字用排版工具叠加上去\n3. 分辨率一定要够高，不然放大打印会糊\n\n结论：AI 绘画适合做氛围图和素材，但精细的文字和信息呈现还是要靠人把关。把它当成「灵感工具」而不是「成品工具」，用起来就顺手多了。",
    author: {
      id: 13,
      name: "刘洋",
      avatar: "/student6.png"
    },
    createdAt: "2024-03-09T16:45:00",
    likes: 92,
    tags: ["AI绘画", "科技节", "设计", "实践经验"],
    comments: [
      {
        id: 1008,
        content: "文字乱码这个问题我也踩过坑，后来用「只生成背景、文字后期加」的思路就稳多了，感谢分享！",
        author: {
          id: 14,
          name: "周杰",
          avatar: "/student10.png"
        },
        createdAt: "2024-03-09T17:20:00",
        likes: 25
      }
    ]
  },
  {
    id: 8,
    title: "如何辨别一段文字是不是 AI 写的？聊聊观察",
    content: "老师布置了一个「找出 AI 生成文本」的练习，我总结了几个观察点：\n\n1. AI 喜欢用「首先、其次、最后」这类很工整的连接词\n2. 段落长度往往很均匀，缺少人那种忽长忽短的节奏\n3. 观点很「周全」，但很少有自己的鲜明立场\n4. 具体的细节和个人经历偏少\n\n但这些都只是概率性的特征，随着模型进步会越来越不准。我觉得更靠谱的思路是：与其纠结「是不是 AI 写的」，不如看内容本身有没有价值、有没有独特的思考。\n\n你们有什么鉴别妙招吗？欢迎留言讨论。",
    author: {
      id: 15,
      name: "吴超",
      avatar: "/student9.png"
    },
    createdAt: "2024-03-08T11:30:00",
    likes: 68,
    tags: ["AI生成内容", "媒介素养", "讨论", "思考"],
    comments: [
      {
        id: 1009,
        content: "同意你的看法，关键还是看内容有没有独立思考。我一般还会看看有没有具体的个人经历，AI 编的细节往往比较空泛。",
        author: {
          id: 16,
          name: "孙伟",
          avatar: "/student8.png"
        },
        createdAt: "2024-03-08T12:15:00",
        likes: 31
      }
    ]
  }
]);

// 新帖子表单数据
const newPost = ref({
  title: '',
  content: '',
  tags: ''
});

// 是否显示发帖表单
const showPostForm = ref(false);

const STORAGE_USER_KEYS = ['userInfo', 'currentUser', 'user', 'loginUser', 'loginData', 'tokenUser', 'studentInfo'];

const currentUser = ref({
  id: 0,
  name: '当前用户',
  avatar: '/example.png'
});

const asRecord = (value: unknown): Record<string, unknown> | null =>
  value !== null && typeof value === 'object' ? (value as Record<string, unknown>) : null;

const parseStorageValue = (raw: string) => {
  const text = raw.trim();
  if (!text) return null;
  if ((text.startsWith('{') && text.endsWith('}')) || (text.startsWith('[') && text.endsWith(']'))) {
    try {
      return JSON.parse(text);
    } catch {
      return raw;
    }
  }
  return raw;
};

const resolveCurrentUserFromStorage = () => {
  if (typeof window === 'undefined') {
    return;
  }

  const storages = [window.localStorage, window.sessionStorage];

  for (const storage of storages) {
    for (const key of STORAGE_USER_KEYS) {
      const raw = storage.getItem(key);
      if (!raw) continue;

      const parsed = parseStorageValue(raw);
      const queue = [parsed];

      while (queue.length) {
        const current = queue.shift();
        const record = asRecord(current);
        if (!record) continue;

        if (record.data) queue.push(record.data);
        if (record.loginData) queue.push(record.loginData);

        const name = [record.userName, record.username, record.name]
          .map((item) => (item === null || item === undefined ? '' : String(item).trim()))
          .find(Boolean);
        if (!name) continue;

        const idValue = [record.userId, record.id]
          .map((item) => Number(item))
          .find((item) => Number.isFinite(item) && item > 0) || 0;
        const avatar = [record.userImage, record.avatar]
          .map((item) => (item === null || item === undefined ? '' : String(item).trim()))
          .find(Boolean) || '/example.png';

        currentUser.value = {
          id: idValue,
          name,
          avatar
        };
        return;
      }
    }
  }
};

// 评论相关
const commentContent = ref('');
const activePostId = ref<number | null>(null);

// 发布新帖子
const publishPost = () => {
  if (!newPost.value.title || !newPost.value.content) {
    alert('标题和内容不能为空');
    return;
  }

  // 模拟发布新帖子
  const tagsArray = newPost.value.tags.split(',').map(tag => tag.trim()).filter(tag => tag);
  
  const newPostObj: Post = {
    id: posts.value.length + 1,
    title: newPost.value.title,
    content: newPost.value.content,
    author: {
      id: currentUser.value.id,
      name: currentUser.value.name,
      avatar: currentUser.value.avatar
    },
    createdAt: new Date().toISOString(),
    likes: 0,
    tags: tagsArray,
    comments: []
  };

  posts.value.unshift(newPostObj);
  
  // 重置表单
  newPost.value = {
    title: '',
    content: '',
    tags: ''
  };
  
  // 关闭表单
  showPostForm.value = false;
};

// 格式化日期
const formatDate = (dateStr: string) => {
  const date = new Date(dateStr);
  return date.toLocaleDateString('zh-CN', { 
    year: 'numeric', 
    month: 'long', 
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
};

// 点赞功能
const likePost = (post: Post) => {
  post.likes++;
};

// 添加评论
const addComment = (post: Post) => {
  if (!commentContent.value.trim()) {
    return;
  }

  const newComment: Comment = {
    id: Math.floor(Math.random() * 10000),
    content: commentContent.value,
    author: {
      id: currentUser.value.id,
      name: currentUser.value.name,
      avatar: currentUser.value.avatar
    },
    createdAt: new Date().toISOString(),
    likes: 0
  };

  post.comments.push(newComment);
  commentContent.value = '';
  activePostId.value = null;
};

// 动画效果
onMounted(() => {
  resolveCurrentUserFromStorage();
});
</script>

<template>
  <div class="community-container">
    <!-- 社区头部 -->
    <div class="mb-8">
      <h1 class="text-3xl font-bold mb-2">立心 LMS · AI 学习社区</h1>
      <p class="text-base-content/70">分享你的 AI 学习心得、实践经验与创作灵感，向社区寻求帮助或提供指导</p>
      
      <div class="flex justify-between items-center mt-6">
        <div class="stats shadow">
          <div class="stat">
            <div class="stat-figure text-primary">
              <i class="fas fa-file-alt text-2xl"></i>
            </div>
            <div class="stat-title">帖子</div>
            <div class="stat-value text-primary">{{ posts.length }}</div>
          </div>
          
          <div class="stat">
            <div class="stat-figure text-secondary">
              <i class="fas fa-users text-2xl"></i>
            </div>
            <div class="stat-title">活跃用户</div>
            <div class="stat-value text-secondary">37</div>
          </div>
        </div>
        
        <button 
          @click="showPostForm = !showPostForm" 
          class="btn btn-primary gap-2"
        >
          <i class="fas fa-edit"></i>
          {{ showPostForm ? '取消' : '发布帖子' }}
        </button>
      </div>
    </div>
    
    <!-- 发布帖子表单 -->
    <div v-if="showPostForm" class="card bg-base-100 shadow-xl mb-8 transition-all duration-300 animate-fade-in">
      <div class="card-body">
        <h2 class="card-title">
          <i class="fas fa-edit mr-2"></i>
          发布新帖子
        </h2>
        
        <div class="form-control">
          <label class="label">
            <span class="label-text">标题</span>
          </label>
          <input 
            v-model="newPost.title" 
            type="text" 
            placeholder="输入帖子标题" 
            class="input input-bordered w-full"
          />
        </div>
        
        <div class="form-control">
          <label class="label">
            <span class="label-text">内容</span>
          </label>
          <textarea 
            v-model="newPost.content" 
            class="textarea textarea-bordered h-32" 
            placeholder="分享你的经验、问题或心得..."
          ></textarea>
        </div>
        
        <div class="form-control">
          <label class="label">
            <span class="label-text">标签（用逗号分隔）</span>
          </label>
          <input 
            v-model="newPost.tags" 
            type="text" 
            placeholder="例如: 图像分类, 提示词, 多智能体" 
            class="input input-bordered w-full"
          />
        </div>
        
        <div class="card-actions justify-end mt-4">
          <button 
            @click="showPostForm = false" 
            class="btn btn-ghost"
          >
            取消
          </button>
          <button 
            @click="publishPost" 
            class="btn btn-primary"
          >
            发布
          </button>
        </div>
      </div>
    </div>
    
    <!-- 帖子列表 -->
    <div class="space-y-6">
      <div 
        v-for="post in posts" 
        :key="post.id" 
        class="card bg-base-100 shadow-xl transition-all duration-300 hover:shadow-2xl"
      >
        <div class="card-body">
          <h2 class="card-title">
            {{ post.title }}
            <div class="badge badge-primary ml-2">{{ post.likes }} 赞</div>
          </h2>
          
          <div class="flex items-center text-sm text-base-content/60 mb-2">
            <div class="avatar mr-2">
              <div class="w-6 h-6 rounded-full">
                <img :src="post.author.avatar" alt="avatar" />
              </div>
            </div>
            <span class="font-medium">{{ post.author.name }}</span>
            <span class="mx-2">·</span>
            <span>{{ formatDate(post.createdAt) }}</span>
          </div>
          
          <p class="text-base-content/80 whitespace-pre-line">{{ post.content }}</p>
          
          <div class="flex flex-wrap gap-2 mt-4">
            <div 
              v-for="tag in post.tags" 
              :key="tag" 
              class="badge badge-outline badge-secondary"
            >
              {{ tag }}
            </div>
          </div>
          
          <div class="divider my-2"></div>
          
          <!-- 互动操作 -->
          <div class="flex items-center space-x-4">
            <button 
              @click="likePost(post)" 
              class="btn btn-sm btn-ghost gap-2"
            >
              <i class="fas fa-thumbs-up"></i>
              赞 ({{ post.likes }})
            </button>
            
            <button 
              @click="activePostId = activePostId === post.id ? null : post.id" 
              class="btn btn-sm btn-ghost gap-2"
            >
              <i class="fas fa-comment"></i>
              评论 ({{ post.comments.length }})
            </button>
            
            <button class="btn btn-sm btn-ghost gap-2">
              <i class="fas fa-share"></i>
              分享
            </button>
          </div>
          
          <!-- 评论区 -->
          <div v-if="activePostId === post.id || post.comments.length > 0" class="mt-4 bg-base-200 rounded-box p-4">
            <!-- 现有评论 -->
            <div v-if="post.comments.length > 0" class="space-y-4 mb-4">
              <h3 class="font-bold text-sm">评论 ({{ post.comments.length }})</h3>
              
              <div 
                v-for="comment in post.comments" 
                :key="comment.id" 
                class="flex items-start space-x-3 p-3 bg-base-100 rounded-lg"
              >
                <div class="avatar">
                  <div class="w-8 h-8 rounded-full">
                    <img :src="comment.author.avatar" alt="avatar" />
                  </div>
                </div>
                
                <div class="flex-1">
                  <div class="flex items-center">
                    <span class="font-medium text-sm">{{ comment.author.name }}</span>
                    <span class="mx-2 text-xs text-base-content/60">·</span>
                    <span class="text-xs text-base-content/60">{{ formatDate(comment.createdAt) }}</span>
                  </div>
                  
                  <p class="mt-1 text-sm">{{ comment.content }}</p>
                  
                  <div class="mt-2 flex items-center space-x-2">
                    <button class="btn btn-xs btn-ghost">
                      <i class="fas fa-thumbs-up mr-1"></i>
                      {{ comment.likes }}
                    </button>
                    <button class="btn btn-xs btn-ghost">回复</button>
                  </div>
                </div>
              </div>
            </div>
            
            <!-- 添加评论 -->
            <div v-if="activePostId === post.id" class="flex items-start space-x-3">
              <div class="avatar">
                <div class="w-8 h-8 rounded-full">
                  <img :src="currentUser.avatar" alt="Your avatar" />
                </div>
              </div>
              
              <div class="flex-1">
                <textarea 
                  v-model="commentContent" 
                  class="textarea textarea-bordered w-full text-sm" 
                  placeholder="写下你的评论..."
                  rows="2"
                ></textarea>
                
                <div class="flex justify-end mt-2">
                  <button 
                    @click="addComment(post)" 
                    class="btn btn-sm btn-primary"
                    :disabled="!commentContent.trim()"
                  >
                    发表评论
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
.community-container {
  max-width: 1400px;
  margin: 0 auto;
  padding-bottom: 100px;
  padding-top: 2rem;  /* 添加顶部内边距 */
}

.stats {
  background-color: rgba(var(--color-base-100), 0.7);
  backdrop-filter: blur(10px);
}

/* 动画 */
@keyframes fade-in {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-fade-in {
  animation: fade-in 0.3s ease-out forwards;
}

/* 卡片悬浮效果 */
.card {
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.card:hover {
  transform: translateY(-5px);
}

/* 标签样式 */
.badge-outline {
  border-width: 1px;
}
</style> 

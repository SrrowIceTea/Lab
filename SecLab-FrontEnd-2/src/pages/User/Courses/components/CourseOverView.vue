<script setup lang="ts">
import type { CourseOverViewType } from './CourseOverView';
import { useRouter } from 'vue-router';

const props = defineProps<{
  course: CourseOverViewType;
}>();

const router = useRouter();

const handleViewDetails = () => {
  router.push(`/user/course/${props.course.id}`);
};
</script>

<template>
  <div class="card bg-base-100 shadow-lg hover:shadow-xl transition-all duration-300 overflow-hidden h-full flex flex-col">
    <!-- 课程图片 -->
    <div class="relative h-48 overflow-hidden">
      <img 
        :src="course.image" 
        :alt="course.name" 
        class="w-full h-full object-cover transition-transform duration-500 hover:scale-110"
      />
      <!-- 状态标签 -->
      <div class="absolute top-2 right-2">
        <span 
          class="badge" 
          :class="{
            'badge-warning': course.status === 'available',
            'badge-info': course.status === 'in-progress',
            'badge-success': course.status === 'completed'
          }"
        >
          {{ course.status === 'available' ? '可开始' : course.status === 'in-progress' ? '进行中' : '已完成' }}
        </span>
      </div>
    </div>
    
    <!-- 课程内容 -->
    <div class="card-body p-4">
      <!-- 课程标题 -->
      <h3 class="card-title text-lg font-semibold mb-2 line-clamp-2">{{ course.name }}</h3>
      
      <!-- 课程描述 -->
      <p class="text-sm text-base-content/70 mb-4 line-clamp-3">{{ course.description }}</p>
      
      <!-- 课程信息 -->
      <div class="grid grid-cols-2 gap-2 mb-4">
        <!-- 难度 -->
        <div class="flex items-center gap-1">
          <i class="fas fa-signal text-primary text-xs"></i>
          <span class="text-xs">{{ '★'.repeat(course.difficulty) }}{{ '☆'.repeat(5 - course.difficulty) }}</span>
        </div>
        
        <!-- 预计用时 -->
        <div class="flex items-center gap-1">
          <i class="fas fa-clock text-primary text-xs"></i>
          <span class="text-xs">{{ course.estimatedHours }}小时</span>
        </div>
      </div>
      
      <!-- 标签 -->
      <div class="flex flex-wrap gap-1 mb-4">
        <span 
          v-for="tag in course.tags" 
          :key="tag" 
          class="text-xs px-2 py-1 bg-primary/10 text-primary rounded-full"
        >
          {{ tag }}
        </span>
      </div>
      
      <!-- 操作按钮 -->
      <div class="card-actions justify-end mt-auto">
        <button class="btn btn-primary btn-sm" @click="handleViewDetails">
          查看详情
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.card {
  transition: all 0.3s ease;
}

.card:hover {
  transform: translateY(-4px);
}

.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.line-clamp-3 {
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
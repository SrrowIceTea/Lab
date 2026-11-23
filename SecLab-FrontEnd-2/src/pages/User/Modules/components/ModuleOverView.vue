<script setup lang="ts">
import type { ModuleOverViewType } from './ModuleOverView';

const props = defineProps<{
  module: ModuleOverViewType;
}>();

const emit = defineEmits<{
  (e: 'startExperiment', moduleId: number): void;
}>();
</script>

<template>
  <div class="card bg-base-100 shadow-xl hover:shadow-2xl transition-all duration-300 overflow-hidden">
    <!-- 卡片头部 -->
    <div class="card-body">
      <!-- 状态标签 -->
      <div class="flex justify-between items-start mb-4">
        <h3 class="card-title text-lg font-semibold">{{ module.name }}</h3>
        <span 
          class="badge" 
          :class="{
            'badge-warning': module.status === 'available',
            'badge-error': module.status === 'locked',
            'badge-success': module.status === 'completed'
          }"
        >
          {{ module.status === 'available' ? '可开始' : module.status === 'locked' ? '未解锁' : '已完成' }}
        </span>
      </div>
      
      <!-- 描述 -->
      <p class="text-sm text-base-content/70 mb-4 line-clamp-3">{{ module.description }}</p>
      
      <!-- 信息行 -->
      <div class="grid grid-cols-2 gap-2 mb-4">
        <!-- 类型 -->
        <div class="flex items-center gap-2">
          <i class="fas fa-tag text-primary"></i>
          <span class="text-sm">{{ module.type }}</span>
        </div>
        
        <!-- 难度 -->
        <div class="flex items-center gap-2">
          <i class="fas fa-signal text-primary"></i>
          <span class="text-sm">{{ '★'.repeat(module.difficulty) }}{{ '☆'.repeat(5 - module.difficulty) }}</span>
        </div>
        
        <!-- 预计用时 -->
        <div class="flex items-center gap-2">
          <i class="fas fa-clock text-primary"></i>
          <span class="text-sm">{{ module.estimatedTime }}</span>
        </div>
        
        <!-- 分数 -->
        <div class="flex items-center gap-2">
          <i class="fas fa-scoreboard text-primary"></i>
          <span class="text-sm font-semibold">{{ module.score }}分</span>
        </div>
      </div>
      
      <!-- 前置要求 -->
      <div v-if="module.prerequisites && module.prerequisites.length > 0" class="mb-4">
        <div class="text-xs text-base-content/60 mb-1">前置要求：</div>
        <div class="flex flex-wrap gap-1">
          <span 
            v-for="prereq in module.prerequisites" 
            :key="prereq" 
            class="text-xs px-2 py-1 bg-base-200 rounded-full"
          >
            实践 {{ prereq }}
          </span>
        </div>
      </div>
      
      <!-- 操作按钮 -->
      <div class="card-actions justify-end">
        <button
          class="btn btn-primary btn-sm"
          :disabled="module.status === 'locked'"
          @click="$emit('startExperiment', module.id)"
        >
          {{ module.status === 'locked' ? '未解锁' : '开始实践' }}
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

.card-actions {
  margin-top: 1rem;
}

.line-clamp-3 {
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
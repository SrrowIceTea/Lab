<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { clearStoredAuthSession, getStoredCurrentUser } from '../../auth'

const route = useRoute()
const router = useRouter()
const mobileOpen = ref(false)
const currentUser = computed(() => getStoredCurrentUser())

const navigation = [
  { label: '教学概览', to: '/teacher/overview', icon: 'home' },
  { label: '教学班', to: '/teacher/classes', icon: 'class' },
  { label: '教学分析', to: '/teacher/analysis', icon: 'analysis' },
  { label: '课程库', to: '/teacher/courses', icon: 'course' },
  { label: '课程资料', to: '/teacher/course-documents', icon: 'docs' },
  { label: '生成题记录', to: '/teacher/generated-questions', icon: 'question' },
]

const active = (to: string) => route.path === to || route.path.startsWith(`${to}/`)
const logout = () => {
  clearStoredAuthSession()
  router.replace('/')
}
</script>

<template>
  <div class="teacher-shell">
    <button class="mobile-menu" type="button" aria-label="打开导航" @click="mobileOpen = true">
      <span></span><span></span><span></span>
    </button>
    <div v-if="mobileOpen" class="nav-backdrop" @click="mobileOpen = false"></div>
    <aside class="teacher-nav" :class="{ open: mobileOpen }">
      <div class="brand">
        <div class="brand-mark">立</div>
        <div>
          <strong>立心 LMS</strong>
          <span>学习管理平台</span>
        </div>
      </div>

      <div class="nav-caption">教师工作台</div>
      <nav>
        <RouterLink
          v-for="item in navigation"
          :key="item.to"
          :to="item.to"
          class="nav-item"
          :class="{ active: active(item.to) }"
          @click="mobileOpen = false"
        >
          <svg v-if="item.icon === 'home'" viewBox="0 0 24 24"><path d="M3 11.5 12 4l9 7.5v8a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/></svg>
          <svg v-else-if="item.icon === 'class'" viewBox="0 0 24 24"><path d="M4 5h16v12H4zM8 21h8M12 17v4M7 9h4M7 12h7"/></svg>
          <svg v-else-if="item.icon === 'course'" viewBox="0 0 24 24"><path d="M4 5.5A2.5 2.5 0 0 1 6.5 3H20v16H6.5a2.5 2.5 0 1 1 0-5H20M7 7h9"/></svg>
          <svg v-else-if="item.icon === 'analysis'" viewBox="0 0 24 24"><path d="M4 19V9M10 19V5M16 19v-7M3 19h18M16 7l3-3M19 4v4M19 4h-4"/></svg>
          <svg v-else-if="item.icon === 'docs'" viewBox="0 0 24 24"><path d="M6 3h9l4 4v14H6zM14 3v5h5M9 12h7M9 16h7"/></svg>
          <svg v-else viewBox="0 0 24 24"><path d="M5 4h14v16H5zM8 8h8M8 12h8M8 16h5"/></svg>
          <span>{{ item.label }}</span>
        </RouterLink>
      </nav>

      <div class="nav-account">
        <div class="account-avatar">{{ (currentUser?.realName || currentUser?.username || '教').slice(0, 1) }}</div>
        <div class="account-copy">
          <strong>{{ currentUser?.realName || currentUser?.username || '教师' }}</strong>
          <span>教师账号</span>
        </div>
        <button type="button" title="退出登录" @click="logout">退出</button>
      </div>
    </aside>
    <main class="teacher-main">
      <RouterView />
    </main>
  </div>
</template>

<style>
:root {
  --teacher-ink: #14213d;
  --teacher-muted: #68758b;
  --teacher-line: #e5eaf1;
  --teacher-blue: #2563eb;
  --teacher-pale: #f5f7fa;
}

.teacher-shell {
  height: 100vh;
  height: 100dvh;
  overflow: hidden;
  background: var(--teacher-pale);
  color: var(--teacher-ink);
}
.teacher-nav { position: fixed; inset: 0 auto 0 0; z-index: 40; display: flex; width: 238px; flex-direction: column; border-right: 1px solid var(--teacher-line); background: #fff; }
.brand { display: flex; align-items: center; gap: 11px; height: 82px; padding: 0 24px; border-bottom: 1px solid #eef1f5; }
.brand-mark { display: grid; width: 34px; height: 34px; place-items: center; border-radius: 9px; color: #fff; background: #1e4fa1; font-size: 18px; font-weight: 800; }
.brand strong, .brand span { display: block; }
.brand strong { font-size: 17px; letter-spacing: .02em; }
.brand span { margin-top: 2px; color: #8290a4; font-size: 11px; }
.nav-caption { padding: 28px 27px 10px; color: #98a3b3; font-size: 11px; font-weight: 700; letter-spacing: .12em; }
.teacher-nav nav { padding: 0 14px; }
.nav-item { display: flex; align-items: center; gap: 13px; margin: 4px 0; padding: 12px 13px; border-radius: 8px; color: #56647a; font-size: 14px; font-weight: 600; transition: .16s ease; }
.nav-item:hover { background: #f4f7fb; color: #1e4fa1; }
.nav-item.active { background: #edf4ff; color: #1e5fbf; }
.nav-item svg { width: 19px; height: 19px; fill: none; stroke: currentColor; stroke-width: 1.8; stroke-linecap: round; stroke-linejoin: round; }
.nav-account { display: flex; align-items: center; gap: 10px; margin-top: auto; padding: 18px 16px; border-top: 1px solid var(--teacher-line); }
.account-avatar { display: grid; width: 34px; height: 34px; flex: 0 0 auto; place-items: center; border-radius: 50%; background: #e8eef8; color: #204b8f; font-weight: 700; }
.account-copy { min-width: 0; flex: 1; }
.account-copy strong, .account-copy span { display: block; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.account-copy strong { font-size: 13px; }
.account-copy span { color: #8b97a8; font-size: 11px; }
.nav-account button { border: 0; background: none; color: #7b8798; font-size: 12px; cursor: pointer; }
.teacher-main {
  height: 100vh;
  height: 100dvh;
  min-height: 0;
  margin-left: 238px;
  overflow-x: hidden;
  overflow-y: auto;
}
.mobile-menu, .nav-backdrop { display: none; }

@media (max-width: 820px) {
  .teacher-nav { transform: translateX(-100%); transition: transform .2s ease; }
  .teacher-nav.open { transform: translateX(0); }
  .teacher-main { margin-left: 0; padding-top: 52px; }
  .mobile-menu { position: fixed; top: 10px; left: 12px; z-index: 35; display: grid; gap: 4px; width: 36px; height: 34px; place-content: center; border: 1px solid #dbe1ea; border-radius: 8px; background: #fff; }
  .mobile-menu span { width: 17px; height: 1.5px; background: #334155; }
  .nav-backdrop { position: fixed; inset: 0; z-index: 39; display: block; background: rgba(15, 23, 42, .3); }
}
</style>

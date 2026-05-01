<template>
  <n-layout has-sider style="height: 100vh">
    <n-layout-sider
      bordered
      collapse-mode="width"
      :collapsed-width="64"
      :width="220"
      :collapsed="appStore.sidebarCollapsed"
      show-trigger
      @collapse="appStore.sidebarCollapsed = true"
      @expand="appStore.sidebarCollapsed = false"
    >
      <div class="logo" :class="{ collapsed: appStore.sidebarCollapsed }">
        <span class="logo-icon">🔥</span>
        <span v-if="!appStore.sidebarCollapsed" class="logo-text">Hinorei</span>
      </div>
      <n-menu
        :collapsed="appStore.sidebarCollapsed"
        :collapsed-width="64"
        :collapsed-icon-size="22"
        :options="menuOptions"
        :value="activeKey"
        @update:value="handleMenuSelect"
      />
    </n-layout-sider>

    <n-layout>
      <n-layout-header bordered style="height: 56px; padding: 0 16px; display: flex; align-items: center; justify-content: space-between">
        <n-text strong style="font-size: 16px">{{ currentTitle }}</n-text>
      </n-layout-header>

      <n-layout-content position="absolute" style="padding: 24px; overflow: hidden; display: flex; flex-direction: column">
        <router-view />
      </n-layout-content>
    </n-layout>
  </n-layout>
</template>

<script setup lang="ts">
import { computed, h } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  NLayout,
  NLayoutSider,
  NLayoutHeader,
  NLayoutContent,
  NMenu,
  NText,
  type MenuOption,
} from 'naive-ui'
import { Icon } from '@iconify/vue'
import { useAppStore } from '@/stores/app'

const appStore = useAppStore()
const route = useRoute()
const router = useRouter()

const navItems = [
  {
    key: 'dashboard',
    label: '总览',
    path: '/dashboard',
    icon: 'carbon:dashboard',
  },
  {
    key: 'chat',
    label: '对话',
    path: '/chat',
    icon: 'carbon:chat',
  },
  {
    key: 'files',
    label: '文件',
    path: '/files',
    icon: 'carbon:folder',
  },
]

const menuOptions = computed<MenuOption[]>(() =>
  navItems.map((item) => ({
    key: item.key,
    label: item.label,
    icon: () => h(Icon, { icon: item.icon, width: 20 }),
  })),
)

const activeKey = computed(() => {
  const matched = navItems.find((item) => route.path.startsWith(item.path))
  return matched?.key ?? 'dashboard'
})

const currentTitle = computed(() => {
  const matched = navItems.find((item) => route.path.startsWith(item.path))
  return matched?.label ?? 'Hinorei'
})

function handleMenuSelect(key: string) {
  const item = navItems.find((n) => n.key === key)
  if (item) router.push(item.path)
}
</script>

<style scoped>
.logo {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 16px;
  font-weight: 700;
  font-size: 18px;
  overflow: hidden;
  white-space: nowrap;
}

.logo.collapsed {
  justify-content: center;
  padding: 16px 0;
}

.logo-icon {
  font-size: 22px;
  flex-shrink: 0;
}
</style>

import { createRouter, createWebHistory } from 'vue-router'
import MainLayout from '@/layouts/MainLayout.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      component: MainLayout,
      redirect: '/dashboard',
      children: [
        {
          path: '/dashboard',
          name: 'Dashboard',
          component: () => import('@/modules/dashboard/index.vue'),
        },
        {
          path: '/chat',
          name: 'Chat',
          component: () => import('@/modules/chat/index.vue'),
        },
        {
          path: '/files',
          name: 'Files',
          component: () => import('@/modules/files/index.vue'),
        },
      ],
    },
  ],
})

export default router

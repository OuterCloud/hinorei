<template>
  <div class="dashboard">
    <n-grid :cols="3" :x-gap="16" :y-gap="16" responsive="screen" :item-responsive="true">
      <!-- Health Status Card -->
      <n-grid-item span="3 m:1">
        <n-card title="系统状态" :bordered="true">
          <template #header-extra>
            <n-badge :type="healthBadgeType" :value="healthStatus?.status ?? '...'" />
          </template>
          <n-spin :show="loading">
            <n-descriptions :column="1" label-placement="left" v-if="healthStatus">
              <n-descriptions-item label="应用名称">
                {{ healthStatus.app_name }}
              </n-descriptions-item>
              <n-descriptions-item label="版本">
                {{ healthStatus.version }}
              </n-descriptions-item>
              <n-descriptions-item label="可用 Providers">
                <n-space>
                  <n-tag
                    v-for="p in healthStatus.providers"
                    :key="p"
                    type="success"
                    size="small"
                  >
                    {{ p }}
                  </n-tag>
                </n-space>
              </n-descriptions-item>
            </n-descriptions>
            <n-empty v-else-if="!loading" description="无法获取健康状态" />
          </n-spin>
        </n-card>
      </n-grid-item>

      <!-- Quick Entry: Chat -->
      <n-grid-item span="3 m:1">
        <n-card hoverable @click="router.push('/chat')" style="cursor: pointer">
          <div class="quick-entry">
            <Icon icon="carbon:chat" width="40" style="color: var(--n-text-color)" />
            <n-text strong style="font-size: 16px; margin-top: 12px">对话</n-text>
            <n-text depth="3">与 AI 进行文本对话，支持 Markdown 渲染</n-text>
          </div>
        </n-card>
      </n-grid-item>

      <!-- Quick Entry: Files -->
      <n-grid-item span="3 m:1">
        <n-card hoverable @click="router.push('/files')" style="cursor: pointer">
          <div class="quick-entry">
            <Icon icon="carbon:folder" width="40" style="color: var(--n-text-color)" />
            <n-text strong style="font-size: 16px; margin-top: 12px">文件管理</n-text>
            <n-text depth="3">上传、浏览并下载文件</n-text>
          </div>
        </n-card>
      </n-grid-item>
    </n-grid>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import {
  NGrid,
  NGridItem,
  NCard,
  NBadge,
  NSpin,
  NDescriptions,
  NDescriptionsItem,
  NTag,
  NSpace,
  NEmpty,
  NText,
} from 'naive-ui'
import { Icon } from '@iconify/vue'
import { getHealth } from '@/api/chat'
import type { HealthStatus } from '@/types'

const router = useRouter()
const loading = ref(false)
const healthStatus = ref<HealthStatus | null>(null)

const healthBadgeType = computed(() => {
  if (!healthStatus.value) return 'default'
  return healthStatus.value.status === 'ok' ? 'success' : 'error'
})

onMounted(async () => {
  loading.value = true
  try {
    healthStatus.value = await getHealth()
  } catch {
    healthStatus.value = null
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
.dashboard {
  max-width: 1000px;
}

.quick-entry {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 16px 0;
  gap: 6px;
  text-align: center;
}
</style>

<template>
  <div class="chat-page">
    <n-card style="height: 100%; display: flex; flex-direction: column" :content-style="{ padding: 0, display: 'flex', flexDirection: 'column', flex: 1 }">
      <template #header>
        <div style="display: flex; align-items: center; justify-content: space-between">
          <span>AI 对话</span>
          <n-button size="small" quaternary @click="chatStore.clearMessages">清空记录</n-button>
        </div>
      </template>
      <MessageList :messages="chatStore.messages" :loading="chatStore.loading" />
      <ChatInput :loading="chatStore.loading" @send="handleSend" />
    </n-card>
  </div>
</template>

<script setup lang="ts">
import { NCard, NButton, useNotification } from 'naive-ui'
import MessageList from './components/MessageList.vue'
import ChatInput from './components/ChatInput.vue'
import { useChatStore } from './store'
import { sendMessage } from '@/api/chat'
import type { Provider } from '@/types'

const chatStore = useChatStore()
const notification = useNotification()

async function handleSend(text: string, provider: Provider, model: string) {
  chatStore.addMessage('user', text)
  chatStore.loading = true
  try {
    const result = await sendMessage({ message: text, provider, model: model || undefined })
    chatStore.addMessage('assistant', result.response, {
      provider: result.provider,
      model: result.model,
    })
  } catch (err) {
    notification.error({
      title: '发送失败',
      content: err instanceof Error ? err.message : '未知错误',
      duration: 4000,
    })
  } finally {
    chatStore.loading = false
  }
}
</script>

<style scoped>
.chat-page {
  height: calc(100vh - 56px - 48px);
  display: flex;
  flex-direction: column;
}
</style>

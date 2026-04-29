<template>
  <div class="message-list" ref="listRef">
    <n-empty v-if="messages.length === 0" description="发送第一条消息开始对话" style="margin-top: 80px" />
    <MessageItem v-for="msg in messages" :key="msg.id" :message="msg" />
    <div v-if="loading" class="loading-indicator">
      <n-spin size="small" />
      <n-text depth="3" style="margin-left: 8px; font-size: 13px">AI 正在思考...</n-text>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, nextTick } from 'vue'
import { NSpin, NEmpty, NText } from 'naive-ui'
import MessageItem from './MessageItem.vue'
import type { Message } from '@/types'

const props = defineProps<{
  messages: Message[]
  loading: boolean
}>()

const listRef = ref<HTMLElement | null>(null)

watch(
  () => [props.messages.length, props.loading],
  async () => {
    await nextTick()
    if (listRef.value) {
      listRef.value.scrollTop = listRef.value.scrollHeight
    }
  },
)
</script>

<style scoped>
.message-list {
  flex: 1;
  overflow-y: auto;
  padding: 16px;
  display: flex;
  flex-direction: column;
}

.loading-indicator {
  display: flex;
  align-items: center;
  padding: 8px 16px;
}
</style>

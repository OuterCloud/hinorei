<template>
  <div class="message-list" ref="listRef">
    <n-empty v-if="messages.length === 0" description="发送第一条消息开始对话" style="margin-top: 80px" />
    <MessageItem
      v-for="(msg, i) in messages"
      :key="msg.id"
      :message="msg"
      :is-streaming="loading && i === messages.length - 1 && msg.role === 'assistant'"
      :on-export-md="onExportMd ? () => onExportMd!(msg) : undefined"
      :on-share="onShare"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, watch, nextTick } from 'vue'
import { NEmpty } from 'naive-ui'
import MessageItem from './MessageItem.vue'
import type { Message } from '@/types'

const props = defineProps<{
  messages: Message[]
  loading: boolean
  onExportMd?: (msg: Message) => void
  onShare?: () => void
}>()

const listRef = ref<HTMLElement | null>(null)

defineExpose({ listRef })

watch(
  () => [
    props.messages.length,
    props.loading,
    props.messages[props.messages.length - 1]?.content,
  ],
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
  min-height: 0;
  overflow-y: auto;
  padding: 16px;
  display: flex;
  flex-direction: column;
}
</style>

<template>
  <div class="message-item" :class="message.role">
    <div class="avatar">
      <n-avatar :size="32" :color="message.role === 'user' ? '#18a058' : '#2080f0'">
        <Icon :icon="message.role === 'user' ? 'carbon:user' : 'carbon:bot'" width="18" />
      </n-avatar>
    </div>
    <div class="bubble">
      <div class="content markdown-body" v-html="renderedContent" />
      <div class="meta">
        <n-text depth="3" style="font-size: 12px">
          {{ formattedTime }}
          <template v-if="message.provider"> · {{ message.provider }}</template>
          <template v-if="message.model"> / {{ message.model }}</template>
        </n-text>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { NAvatar, NText } from 'naive-ui'
import { Icon } from '@iconify/vue'
import MarkdownIt from 'markdown-it'
import hljs from 'highlight.js'
import type { Message } from '@/types'

const props = defineProps<{ message: Message }>()

const md: MarkdownIt = new MarkdownIt({
  highlight(str: string, lang: string): string {
    if (lang && hljs.getLanguage(lang)) {
      try {
        return (
          '<pre class="hljs"><code>' +
          hljs.highlight(str, { language: lang, ignoreIllegals: true }).value +
          '</code></pre>'
        )
      } catch {}
    }
    return '<pre class="hljs"><code>' + md.utils.escapeHtml(str) + '</code></pre>'
  },
  breaks: true,
  linkify: true,
})

const renderedContent = computed(() => {
  if (props.message.role === 'assistant') {
    return md.render(props.message.content)
  }
  return md.utils.escapeHtml(props.message.content).replace(/\n/g, '<br>')
})

const formattedTime = computed(() => {
  return new Date(props.message.timestamp).toLocaleTimeString('zh-CN', {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  })
})
</script>

<style scoped>
.message-item {
  display: flex;
  gap: 12px;
  margin-bottom: 16px;
}

.message-item.user {
  flex-direction: row-reverse;
}

.bubble {
  max-width: 70%;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.message-item.user .bubble {
  align-items: flex-end;
}

.content {
  padding: 10px 14px;
  border-radius: 8px;
  background: var(--n-color);
  line-height: 1.6;
  word-break: break-word;
}

.message-item.user .content {
  background: #18a05815;
}

.meta {
  padding: 0 4px;
}
</style>

<style>
.markdown-body pre.hljs {
  border-radius: 6px;
  padding: 12px;
  overflow-x: auto;
  margin: 8px 0;
}

.markdown-body code:not(.hljs) {
  background: rgba(128, 128, 128, 0.15);
  padding: 2px 4px;
  border-radius: 3px;
  font-size: 0.9em;
}

.markdown-body p {
  margin: 0 0 8px;
}

.markdown-body p:last-child {
  margin-bottom: 0;
}
</style>

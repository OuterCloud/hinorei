<template>
  <div class="message-item" :class="message.role">
    <div class="avatar">
      <n-avatar :size="32" :color="message.role === 'user' ? '#18a058' : '#2080f0'">
        <Icon :icon="message.role === 'user' ? 'carbon:user' : 'carbon:bot'" width="18" />
      </n-avatar>
    </div>
    <div class="bubble">
      <div v-if="isStreaming && !message.content" class="content">
        <span class="typing-dots"><span /><span /><span /></span>
      </div>
      <div v-else class="content markdown-body" v-html="renderedContent" @click="handleContentClick" />
      <div class="meta">
        <n-text depth="3" style="font-size: 12px">
          {{ formattedTime }}
          <template v-if="message.provider"> · {{ message.provider }}</template>
          <template v-if="message.model"> / {{ message.model }}</template>
        </n-text>
        <n-button text size="tiny" :title="copied ? '已复制' : '复制'" @click="copyContent">
          <Icon :icon="copied ? 'carbon:checkmark' : 'carbon:copy'" width="13" />
        </n-button>
        <template v-if="onExportMd || onShare">
          <n-button v-if="onExportMd" text size="tiny" title="导出为 Markdown" @click="onExportMd">
            <Icon icon="carbon:document-export" width="13" />
          </n-button>
          <n-button v-if="onShare" text size="tiny" title="分享截图" @click="onShare">
            <Icon icon="carbon:share" width="13" />
          </n-button>
        </template>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { NAvatar, NText, NButton } from 'naive-ui'
import { Icon } from '@iconify/vue'
import MarkdownIt from 'markdown-it'
import hljs from 'highlight.js'
import type { Message } from '@/types'

const props = defineProps<{
  message: Message
  isStreaming?: boolean
  onExportMd?: () => void
  onShare?: () => void
}>()

const md: MarkdownIt = new MarkdownIt({ breaks: true, linkify: true })

// 直接接管 fence 渲染，避免 markdown-it 二次包裹 <pre><code>
md.renderer.rules.fence = (tokens, idx) => {
  const token = tokens[idx]
  const lang = token.info.trim().split(/\s+/)[0] || ''
  const str = token.content
  const highlighted = lang && hljs.getLanguage(lang)
    ? hljs.highlight(str, { language: lang, ignoreIllegals: true }).value
    : md.utils.escapeHtml(str)
  const encodedCode = encodeURIComponent(str)
  const langLabel = lang || 'code'
  return (
    `<div class="code-block-wrapper">` +
    `<div class="code-block-header">` +
    `<span class="code-lang">${langLabel}</span>` +
    `<button class="code-copy-btn" data-code="${encodedCode}">复制</button>` +
    `</div>` +
    `<pre class="hljs"><code>${highlighted}</code></pre>` +
    `</div>`
  )
}

const renderedContent = computed(() => {
  if (props.message.role === 'assistant') {
    return md.render(props.message.content)
  }
  return md.utils.escapeHtml(props.message.content).replace(/\n/g, '<br>')
})

const copied = ref(false)

async function copyContent() {
  await navigator.clipboard.writeText(props.message.content)
  copied.value = true
  setTimeout(() => { copied.value = false }, 1500)
}

async function handleContentClick(e: MouseEvent) {
  const btn = (e.target as HTMLElement).closest('.code-copy-btn') as HTMLButtonElement | null
  if (!btn) return
  const code = decodeURIComponent(btn.dataset.code ?? '')
  await navigator.clipboard.writeText(code)
  const prev = btn.textContent
  btn.textContent = '已复制'
  btn.classList.add('copied')
  setTimeout(() => { btn.textContent = prev; btn.classList.remove('copied') }, 1500)
}

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
  display: flex;
  align-items: center;
  gap: 6px;
}

.typing-dots {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 4px 2px;
}

.typing-dots span {
  display: inline-block;
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: currentColor;
  opacity: 0.4;
  animation: typing-bounce 1.2s ease-in-out infinite;
}

.typing-dots span:nth-child(2) { animation-delay: 0.2s; }
.typing-dots span:nth-child(3) { animation-delay: 0.4s; }

@keyframes typing-bounce {
  0%, 80%, 100% { transform: translateY(0); opacity: 0.4; }
  40%           { transform: translateY(-5px); opacity: 1; }
}
</style>

<style>
/* 气泡背景透明，避免 github-markdown-css 的 canvas 色覆盖气泡 */
.markdown-body {
  background: transparent !important;
  color: inherit;
  font-size: 14px;
}

/* ── 代码块容器 ── */
.markdown-body .code-block-wrapper {
  border-radius: 8px;
  overflow: hidden;
  margin: 10px 0;
  border: 1px solid #30363d;
}

/* ── 顶部栏 ── */
.markdown-body .code-block-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 6px 14px;
  background: #161b22;
  border-bottom: 1px solid #30363d;
}

.markdown-body .code-lang {
  font-size: 12px;
  color: #8b949e;
  font-family: ui-monospace, monospace;
}

.markdown-body .code-copy-btn {
  font-size: 12px;
  color: #8b949e;
  background: transparent;
  border: none;
  cursor: pointer;
  padding: 2px 8px;
  border-radius: 4px;
  transition: color 0.15s, background 0.15s;
  font-family: inherit;
}

.markdown-body .code-copy-btn:hover {
  color: #e6edf3;
  background: rgba(255, 255, 255, 0.08);
}

.markdown-body .code-copy-btn.copied {
  color: #3fb950;
}

/* ── 代码内容区（hljs 渲染） ── */
.markdown-body pre.hljs {
  margin: 0;
  padding: 14px 16px;
  overflow-x: auto;
  background: #0d1117;
  border-radius: 0;
  line-height: 1.6;
}

.markdown-body pre.hljs code {
  background: transparent !important;
  padding: 0;
  font-size: 13px;
  font-family: ui-monospace, 'Cascadia Code', 'Fira Code', Consolas, monospace;
  color: #e6edf3;
}
</style>

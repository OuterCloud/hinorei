<template>
  <n-modal
    v-model:show="show"
    :title="filename"
    style="width: min(860px, 92vw)"
    preset="card"
    :segmented="{ content: true }"
    content-style="padding: 0; display: flex; flex-direction: column; max-height: 72vh; overflow: hidden;"
  >
    <div v-if="loading" style="display:flex;justify-content:center;padding:40px">
      <n-spin />
    </div>
    <div
      v-else
      class="preview-body markdown-body"
      v-html="rendered"
      @click="handleContentClick"
    />
  </n-modal>
</template>

<script setup lang="ts">
import { ref, watch, computed } from 'vue'
import { NModal, NSpin } from 'naive-ui'
import MarkdownIt from 'markdown-it'
import hljs from 'highlight.js'
import { getFileContent } from '@/api/files'

const props = defineProps<{ filename: string }>()
const show = defineModel<boolean>('show', { required: true })

const loading = ref(false)
const content = ref('')

const md = new MarkdownIt({ breaks: true, linkify: true })
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

const rendered = computed(() => md.render(content.value))

watch(show, async (val) => {
  if (!val || !props.filename) return
  loading.value = true
  content.value = ''
  try {
    content.value = await getFileContent(props.filename)
  } finally {
    loading.value = false
  }
})

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
</script>

<style scoped>
.preview-body {
  flex: 1;
  min-height: 0;
  overflow-y: auto;
  padding: 24px 28px;
  background: transparent;
  font-size: 14px;
  line-height: 1.7;
}
</style>

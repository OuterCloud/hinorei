<template>
  <div class="chat-page">
    <n-card style="height: 100%; display: flex; flex-direction: column" :content-style="{ padding: 0, display: 'flex', flexDirection: 'column', flex: 1, minHeight: 0 }">
      <template #header>
        <div style="display: flex; align-items: center; justify-content: space-between">
          <span>AI 对话</span>
          <n-button size="small" quaternary @click="chatStore.clearMessages">清空记录</n-button>
        </div>
      </template>
      <MessageList
        ref="messageListRef"
        :messages="chatStore.messages"
        :loading="chatStore.loading"
        :on-export-md="handleExportMd"
        :on-share="() => showShare = true"
      />
      <ChatInput
        :loading="chatStore.loading"
        @send="handleSend"
        @stop="handleStop"
      />
    </n-card>
    <ShareModal
      v-model:show="showShare"
      :message-list-el="messageListRef?.listRef ?? null"
    />

    <!-- 导出文件名弹窗 -->
    <n-modal v-model:show="showExportDialog" preset="dialog" title="导出为 Markdown" @after-leave="exportFilename = ''">
      <n-input
        v-model:value="exportFilename"
        placeholder="输入文件名（无需填写 .md 扩展名）"
        @keydown.enter="confirmExport"
      />
      <template #action>
        <n-button @click="showExportDialog = false">取消</n-button>
        <n-button type="primary" :loading="exporting" :disabled="!exportFilename.trim()" @click="confirmExport">
          导出
        </n-button>
      </template>
    </n-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, h } from 'vue'
import { NCard, NButton, NModal, NInput, useNotification } from 'naive-ui'
import { useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import MessageList from './components/MessageList.vue'
import ChatInput from './components/ChatInput.vue'
import ShareModal from './components/ShareModal.vue'
import { useChatStore } from './store'
import { sendMessageStream } from '@/api/chat'
import { saveMarkdown } from '@/api/files'
import type { Provider, Message } from '@/types'

const chatStore = useChatStore()
const notification = useNotification()
const router = useRouter()
const showShare = ref(false)
const showExportDialog = ref(false)
const exportFilename = ref('')
const exporting = ref(false)
const messageListRef = ref<InstanceType<typeof MessageList> | null>(null)
let pendingExportContent = ''

function handleExportMd(msg: Message) {
  const now = new Date().toLocaleString('zh-CN')
  const meta = [msg.provider, msg.model].filter(Boolean).join(' / ')
  const roleLabel = msg.role === 'user' ? '用户' : `AI${meta ? ` (${meta})` : ''}`
  pendingExportContent = `# ${roleLabel}\n\n> 导出时间：${now}\n\n---\n\n${msg.content}`
  const ts = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19)
  exportFilename.value = `msg-${ts}`
  showExportDialog.value = true
}

async function confirmExport() {
  const name = exportFilename.value.trim()
  if (!name) return
  exporting.value = true
  try {
    const { filename } = await saveMarkdown(name, pendingExportContent)
    showExportDialog.value = false
    notification.success({
      title: '导出成功',
      content: `已保存为 ${filename}，可在文件页面下载`,
      action: () => h(NButton, { text: true, type: 'primary', onClick: () => router.push('/files') }, { default: () => '查看文件' }),
      duration: 5000,
    })
  } catch (err) {
    notification.error({
      title: '导出失败',
      content: err instanceof Error ? err.message : '未知错误',
      duration: 4000,
    })
  } finally {
    exporting.value = false
  }
}

let abortController: AbortController | null = null

function handleStop() {
  abortController?.abort()
}

async function handleSend(text: string, provider: Provider, model: string) {
  abortController = new AbortController()
  chatStore.addMessage('user', text)
  chatStore.loading = true
  chatStore.addMessage('assistant', '', { provider, model })
  try {
    await sendMessageStream(
      { message: text, provider, model: model || undefined },
      (delta) => chatStore.appendToLastMessage(delta),
      abortController.signal,
    )
  } catch (err) {
    if (err instanceof Error && err.name === 'AbortError') {
      // 用户主动停止，保留已有内容，不提示错误
    } else {
      chatStore.removeLastMessage()
      notification.error({
        title: '发送失败',
        content: err instanceof Error ? err.message : '未知错误',
        duration: 4000,
      })
    }
  } finally {
    chatStore.loading = false
    abortController = null
  }
}
</script>

<style scoped>
.chat-page {
  height: 100%;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
</style>

<template>
  <div class="chat-input-area">
    <div class="toolbar">
      <n-select
        v-model:value="provider"
        :options="providerOptions"
        size="small"
        style="width: 140px"
        @update:value="onProviderChange"
      />
      <n-select
        v-if="provider === 'llm_bridge'"
        v-model:value="model"
        :options="modelOptions"
        :loading="modelsLoading"
        placeholder="选择模型"
        size="small"
        style="width: 200px"
        clearable
      />
    </div>
    <div class="input-row">
      <n-input
        v-model:value="inputText"
        type="textarea"
        placeholder="输入消息... (Enter 发送，Shift+Enter 换行，↑↓ 历史记录)"
        :autosize="{ minRows: 1, maxRows: 6 }"
        :disabled="loading"
        @keydown="handleKeydown"
      />
      <n-button
        v-if="loading"
        type="error"
        @click="emit('stop')"
        style="height: 100%; min-height: 34px"
      >
        <template #icon>
          <Icon icon="carbon:stop-filled" />
        </template>
        停止
      </n-button>
      <n-button
        v-else
        type="primary"
        :disabled="!inputText.trim()"
        @click="handleSend"
        style="height: 100%; min-height: 34px"
      >
        <template #icon>
          <Icon icon="carbon:send" />
        </template>
        发送
      </n-button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, nextTick } from 'vue'
import { NInput, NButton, NSelect } from 'naive-ui'
import { Icon } from '@iconify/vue'
import type { Provider } from '@/types'
import { getModels } from '@/api/chat'
import { useChatStore } from '../store'

const props = defineProps<{ loading: boolean }>()
const emit = defineEmits<{
  send: [text: string, provider: Provider, model: string]
  stop: []
}>()

const chatStore = useChatStore()

const inputText = ref('')
const modelList = ref<string[]>([])
const modelsLoading = ref(false)

// provider / model 从 store 读写，切换页面后保持选择
const provider = computed<Provider>({
  get: () => chatStore.provider,
  set: (v) => { chatStore.provider = v },
})
const model = computed<string>({
  get: () => chatStore.model,
  set: (v) => { chatStore.model = v },
})

const providerOptions = computed(() => [
  { label: 'LLM Bridge', value: 'llm_bridge' },
  { label: 'MiniMax', value: 'minimax' },
])

const modelOptions = computed(() =>
  modelList.value.map((m) => ({ label: m, value: m })),
)

const DEFAULT_MODEL = 'claude-sonnet-4-6'

async function fetchModels() {
  modelsLoading.value = true
  try {
    modelList.value = await getModels()
    if (modelList.value.length > 0 && !model.value) {
      model.value = modelList.value.includes(DEFAULT_MODEL)
        ? DEFAULT_MODEL
        : modelList.value[0]
    }
  } catch {
    modelList.value = []
  } finally {
    modelsLoading.value = false
  }
}

function onProviderChange(val: Provider) {
  model.value = ''
  if (val === 'llm_bridge') fetchModels()
}

onMounted(() => {
  if (provider.value === 'llm_bridge') fetchModels()
})

// 输入历史
const history = ref<string[]>([])
const historyIndex = ref(-1)  // -1 表示当前输入，非历史
const savedInput = ref('')    // 进入历史导航前保存的当前输入

function handleKeydown(e: KeyboardEvent) {
  if (e.key === 'Enter' && !e.shiftKey) {
    e.preventDefault()
    handleSend()
    return
  }

  const ta = e.target as HTMLTextAreaElement

  if (e.key === 'ArrowUp' && ta.selectionStart === 0 && history.value.length > 0) {
    e.preventDefault()
    if (historyIndex.value === -1) {
      savedInput.value = inputText.value
      historyIndex.value = history.value.length - 1
    } else if (historyIndex.value > 0) {
      historyIndex.value--
    }
    inputText.value = history.value[historyIndex.value]
    nextTick(() => { ta.selectionStart = ta.selectionEnd = 0 })
    return
  }

  if (e.key === 'ArrowDown' && historyIndex.value !== -1) {
    e.preventDefault()
    if (historyIndex.value < history.value.length - 1) {
      historyIndex.value++
      inputText.value = history.value[historyIndex.value]
    } else {
      historyIndex.value = -1
      inputText.value = savedInput.value
    }
    nextTick(() => { ta.selectionStart = ta.selectionEnd = inputText.value.length })
  }
}

function handleSend() {
  const text = inputText.value.trim()
  if (!text || props.loading) return
  // 避免连续重复记录
  if (history.value[history.value.length - 1] !== text) {
    history.value.push(text)
  }
  historyIndex.value = -1
  savedInput.value = ''
  emit('send', text, provider.value, model.value)
  inputText.value = ''
}
</script>

<style scoped>
.chat-input-area {
  border-top: 1px solid var(--n-border-color);
  padding: 12px 16px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.toolbar {
  display: flex;
  gap: 8px;
  align-items: center;
}

.input-row {
  display: flex;
  gap: 8px;
  align-items: flex-end;
}
</style>

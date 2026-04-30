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
        placeholder="输入消息... (Enter 发送，Shift+Enter 换行)"
        :autosize="{ minRows: 1, maxRows: 6 }"
        :disabled="loading"
        @keydown.enter.exact.prevent="handleSend"
      />
      <n-button
        type="primary"
        :disabled="!inputText.trim() || loading"
        :loading="loading"
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
import { ref, computed } from 'vue'
import { NInput, NButton, NSelect } from 'naive-ui'
import { Icon } from '@iconify/vue'
import type { Provider } from '@/types'
import { getModels } from '@/api/chat'

const props = defineProps<{ loading: boolean }>()
const emit = defineEmits<{
  send: [text: string, provider: Provider, model: string]
}>()

const inputText = ref('')
const provider = ref<Provider>('minimax')
const model = ref('')
const modelList = ref<string[]>([])
const modelsLoading = ref(false)

const providerOptions = computed(() => [
  { label: 'MiniMax', value: 'minimax' },
  { label: 'LLM Bridge', value: 'llm_bridge' },
])

const modelOptions = computed(() =>
  modelList.value.map((m) => ({ label: m, value: m })),
)

async function fetchModels() {
  modelsLoading.value = true
  try {
    modelList.value = await getModels()
    if (modelList.value.length > 0 && !model.value) {
      model.value = modelList.value[0]
    }
  } catch {
    modelList.value = []
  } finally {
    modelsLoading.value = false
  }
}

function onProviderChange(val: Provider) {
  model.value = ''
  if (val === 'llm_bridge') {
    fetchModels()
  }
}

function handleSend() {
  const text = inputText.value.trim()
  if (!text || props.loading) return
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

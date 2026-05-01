import { defineStore } from 'pinia'
import { ref } from 'vue'
import { nanoid } from './nanoid'
import type { Message, Provider } from '@/types'

export const useChatStore = defineStore('chat', () => {
  const messages = ref<Message[]>([])
  const loading = ref(false)
  const provider = ref<Provider>('llm_bridge')
  const model = ref<string>('claude-sonnet-4-6')

  function addMessage(role: Message['role'], content: string, extra?: Partial<Message>) {
    messages.value.push({
      id: nanoid(),
      role,
      content,
      timestamp: Date.now(),
      ...extra,
    })
  }

  function appendToLastMessage(delta: string) {
    const last = messages.value[messages.value.length - 1]
    if (last?.role === 'assistant') last.content += delta
  }

  function removeLastMessage() {
    messages.value.pop()
  }

  function clearMessages() {
    messages.value = []
  }

  return { messages, loading, provider, model, addMessage, appendToLastMessage, removeLastMessage, clearMessages }
})

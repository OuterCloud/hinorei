import { defineStore } from 'pinia'
import { ref } from 'vue'
import { nanoid } from './nanoid'
import type { Message, Provider } from '@/types'

export const useChatStore = defineStore('chat', () => {
  const messages = ref<Message[]>([])
  const loading = ref(false)
  const provider = ref<Provider>('minimax')
  const model = ref<string>('')

  function addMessage(role: Message['role'], content: string, extra?: Partial<Message>) {
    messages.value.push({
      id: nanoid(),
      role,
      content,
      timestamp: Date.now(),
      ...extra,
    })
  }

  function clearMessages() {
    messages.value = []
  }

  return { messages, loading, provider, model, addMessage, clearMessages }
})

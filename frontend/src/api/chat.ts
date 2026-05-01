import client from './client'
import type { ChatRequest, ChatResponse, HealthStatus } from '@/types'

// Backend returns { reply: string }, map to our ChatResponse shape
export async function sendMessage(payload: ChatRequest): Promise<ChatResponse> {
  const { data } = await client.post<{ reply: string; model?: string }>(
    '/chat',
    {
      message: payload.message,
      provider: payload.provider,
      model: payload.model ?? '',
    },
    { timeout: 120_000 },  // LLM 响应可能较慢，单独设 2 分钟
  )
  return {
    response: data.reply,
    provider: payload.provider,
    model: data.model ?? '',
  }
}

export async function sendMessageStream(
  payload: ChatRequest,
  onDelta: (delta: string) => void,
  signal?: AbortSignal,
): Promise<void> {
  const res = await fetch('/api/v1/chat/stream', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      message: payload.message,
      provider: payload.provider,
      model: payload.model ?? '',
    }),
    signal,
  })
  if (!res.ok) throw new Error(`HTTP ${res.status}`)

  const reader = res.body!.getReader()
  const decoder = new TextDecoder()
  let buf = ''

  while (true) {
    const { done, value } = await reader.read()
    if (done) break
    buf += decoder.decode(value, { stream: true })
    const lines = buf.split('\n')
    buf = lines.pop() ?? ''
    for (const line of lines) {
      if (!line.startsWith('data: ')) continue
      const data = line.slice(6).trim()
      if (data === '[DONE]') return
      let obj: Record<string, string>
      try { obj = JSON.parse(data) } catch { continue }
      if (obj.error) throw new Error(obj.error)
      if (obj.delta) onDelta(obj.delta)
    }
  }
}

export async function getHealth(): Promise<HealthStatus> {
  const { data } = await client.get<HealthStatus>('/health')
  return data
}

export async function getModels(): Promise<string[]> {
  const { data } = await client.get<{ models: string[] }>('/models')
  return data.models
}

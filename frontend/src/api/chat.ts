import client from './client'
import type { ChatRequest, ChatResponse, HealthStatus } from '@/types'

// Backend returns { reply: string }, map to our ChatResponse shape
export async function sendMessage(payload: ChatRequest): Promise<ChatResponse> {
  const { data } = await client.post<{ reply: string; model?: string }>('/chat', {
    message: payload.message,
    provider: payload.provider,
    model: payload.model ?? '',
  })
  return {
    response: data.reply,
    provider: payload.provider,
    model: data.model ?? '',
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

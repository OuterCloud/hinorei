// Chat types
export interface Message {
  id: string
  role: 'user' | 'assistant'
  content: string
  timestamp: number
  provider?: string
  model?: string
}

export interface ChatRequest {
  message: string
  provider: string
  model?: string
}

export interface ChatResponse {
  response: string
  provider: string
  model: string
}

// File types
export interface FileInfo {
  name: string
  size: number
  modified: number
}

export interface FileListResponse {
  files: FileInfo[]
}

export interface UploadResponse {
  message: string
}

// Health types
export interface HealthStatus {
  status: string
  app_name: string
  version: string
  providers: string[]
}

// Provider types
export type Provider = 'minimax' | 'llm_bridge'

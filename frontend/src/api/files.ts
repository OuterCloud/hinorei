import client from './client'
import type { FileListResponse, UploadResponse } from '@/types'

export async function listFiles(): Promise<FileListResponse> {
  const { data } = await client.get<FileListResponse>('/files/list')
  return data
}

export async function downloadFile(filename: string): Promise<void> {
  const response = await client.get(`/files/download/${encodeURIComponent(filename)}`, {
    responseType: 'blob',
  })
  const url = window.URL.createObjectURL(new Blob([response.data]))
  const link = document.createElement('a')
  link.href = url
  link.setAttribute('download', filename)
  document.body.appendChild(link)
  link.click()
  link.remove()
  window.URL.revokeObjectURL(url)
}

export async function getFileContent(filename: string): Promise<string> {
  const { data } = await client.get<{ content: string }>(`/files/content/${encodeURIComponent(filename)}`)
  return data.content
}

export async function renameFile(filename: string, newName: string): Promise<{ filename: string }> {
  const { data } = await client.patch(`/files/rename/${encodeURIComponent(filename)}`, { new_name: newName })
  return data
}

export async function deleteFile(filename: string): Promise<void> {
  await client.delete(`/files/delete/${encodeURIComponent(filename)}`)
}

export async function saveMarkdown(
  filename: string,
  content: string,
): Promise<{ filename: string; size: number }> {
  const { data } = await client.post('/files/save-markdown', { filename, content })
  return data
}

export async function uploadFile(
  file: File,
  onProgress?: (percent: number) => void,
): Promise<UploadResponse> {
  const formData = new FormData()
  formData.append('file', file)
  const { data } = await client.post<UploadResponse>('/files/upload', formData, {
    headers: { 'Content-Type': 'multipart/form-data' },
    onUploadProgress: (event) => {
      if (onProgress && event.total) {
        onProgress(Math.round((event.loaded * 100) / event.total))
      }
    },
  })
  return data
}

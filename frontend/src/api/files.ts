import client from './client'
import type { FileListResponse, UploadResponse } from '@/types'

export async function listFiles(): Promise<FileListResponse> {
  const { data } = await client.get<FileListResponse>('/files/list')
  return data
}

export async function downloadFile(
  filename: string,
  onProgress?: (percent: number) => void,
): Promise<string> {
  const response = await client.get(`/files/download/${encodeURIComponent(filename)}`, {
    responseType: 'blob',
    timeout: 0,
    onDownloadProgress: (event) => {
      if (onProgress && event.total) {
        onProgress(Math.round((event.loaded * 100) / event.total))
      } else if (onProgress && event.loaded) {
        // 服务端未返回 Content-Length 时显示已下载大小（负数表示未知总量）
        onProgress(-event.loaded)
      }
    },
  })

  const blob = new Blob([response.data])

  // 优先使用 File System Access API（安全上下文），否则 fallback 到 <a> 下载
  if (typeof window.showSaveFilePicker === 'function') {
    const handle = await window.showSaveFilePicker({
      suggestedName: filename,
    })
    const writable = await handle.createWritable()
    await writable.write(blob)
    await writable.close()
    return handle.name
  }

  // Fallback: 创建临时链接触发下载
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
  return filename
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

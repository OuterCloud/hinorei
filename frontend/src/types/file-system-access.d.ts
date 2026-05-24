interface FileSystemWritableFileStream extends WritableStream {
  write(data: BufferSource | Blob | string | { type: string; data?: BufferSource | Blob | string; position?: number; size?: number }): Promise<void>
  seek(position: number): Promise<void>
  truncate(size: number): Promise<void>
  close(): Promise<void>
}

interface FileSystemFileHandle {
  readonly kind: 'file'
  readonly name: string
  createWritable(): Promise<FileSystemWritableFileStream>
}

interface SaveFilePickerOptions {
  suggestedName?: string
  types?: Array<{
    description?: string
    accept: Record<string, string[]>
  }>
}

interface Window {
  showSaveFilePicker(options?: SaveFilePickerOptions): Promise<FileSystemFileHandle>
}

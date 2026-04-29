import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { FileInfo } from '@/types'
import { listFiles } from '@/api/files'

export const useFilesStore = defineStore('files', () => {
  const files = ref<FileInfo[]>([])
  const loading = ref(false)

  async function fetchFiles() {
    loading.value = true
    try {
      const result = await listFiles()
      files.value = result.files
    } finally {
      loading.value = false
    }
  }

  return { files, loading, fetchFiles }
})

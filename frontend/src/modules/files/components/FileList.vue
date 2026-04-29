<template>
  <n-data-table
    :columns="columns"
    :data="files"
    :loading="loading"
    :pagination="{ pageSize: 20 }"
    :bordered="false"
    size="small"
  />
</template>

<script setup lang="ts">
import { h } from 'vue'
import { NDataTable, NButton, NText, useNotification } from 'naive-ui'
import type { DataTableColumns } from 'naive-ui'
import type { FileInfo } from '@/types'
import { downloadFile } from '@/api/files'

defineProps<{ files: FileInfo[]; loading: boolean }>()
const notification = useNotification()

function formatSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / 1024 / 1024).toFixed(2)} MB`
}

function formatTime(ts: number): string {
  return new Date(ts * 1000).toLocaleString('zh-CN')
}

async function handleDownload(filename: string) {
  try {
    await downloadFile(filename)
  } catch (err) {
    notification.error({
      title: '下载失败',
      content: err instanceof Error ? err.message : '未知错误',
      duration: 4000,
    })
  }
}

const columns: DataTableColumns<FileInfo> = [
  {
    title: '文件名',
    key: 'name',
    render: (row) => h(NText, null, { default: () => row.name }),
  },
  {
    title: '大小',
    key: 'size',
    width: 100,
    render: (row) => formatSize(row.size),
  },
  {
    title: '修改时间',
    key: 'modified',
    width: 180,
    render: (row) => formatTime(row.modified),
  },
  {
    title: '操作',
    key: 'actions',
    width: 90,
    render: (row) =>
      h(
        NButton,
        {
          size: 'small',
          type: 'primary',
          ghost: true,
          onClick: () => handleDownload(row.name),
        },
        { default: () => '下载' },
      ),
  },
]
</script>

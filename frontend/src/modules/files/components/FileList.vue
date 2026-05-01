<template>
  <n-data-table
    :columns="columns"
    :data="files"
    :loading="loading"
    :pagination="{ pageSize: 20 }"
    :bordered="false"
    size="small"
  />

  <!-- Markdown 预览弹窗 -->
  <FilePreviewModal v-model:show="previewVisible" :filename="previewFilename" />

  <!-- 重命名弹窗 -->
  <n-modal v-model:show="renameVisible" preset="dialog" title="重命名文件" @after-leave="renameInput = ''">
    <n-input v-model:value="renameInput" placeholder="新文件名" @keydown.enter="confirmRename" />
    <template #action>
      <n-button @click="renameVisible = false">取消</n-button>
      <n-button type="primary" :loading="renaming" :disabled="!renameInput.trim()" @click="confirmRename">确认</n-button>
    </template>
  </n-modal>
</template>

<script setup lang="ts">
import { h, ref } from 'vue'
import { NDataTable, NButton, NText, NModal, NInput, useNotification, useDialog } from 'naive-ui'
import type { DataTableColumns } from 'naive-ui'
import type { FileInfo } from '@/types'
import { downloadFile, renameFile, deleteFile } from '@/api/files'
import FilePreviewModal from './FilePreviewModal.vue'

const props = defineProps<{ files: FileInfo[]; loading: boolean }>()
const emit = defineEmits<{ refresh: [] }>()

const notification = useNotification()
const dialog = useDialog()

// ── 预览 ─────────────────────────────────────────
const previewVisible = ref(false)
const previewFilename = ref('')

// ── 重命名 ──────────────────────────────────────
const renameVisible = ref(false)
const renameInput = ref('')
const renaming = ref(false)
let renamingFile = ''

function openRename(filename: string) {
  renamingFile = filename
  renameInput.value = filename
  renameVisible.value = true
}

async function confirmRename() {
  const newName = renameInput.value.trim()
  if (!newName || newName === renamingFile) { renameVisible.value = false; return }
  renaming.value = true
  try {
    await renameFile(renamingFile, newName)
    notification.success({ title: '重命名成功', duration: 2500 })
    renameVisible.value = false
    emit('refresh')
  } catch (err) {
    notification.error({ title: '重命名失败', content: err instanceof Error ? err.message : '未知错误', duration: 4000 })
  } finally {
    renaming.value = false
  }
}

// ── 删除 ────────────────────────────────────────
function openDelete(filename: string) {
  dialog.warning({
    title: '确认删除',
    content: `确定要删除文件 "${filename}" 吗？此操作不可撤销。`,
    positiveText: '删除',
    negativeText: '取消',
    onPositiveClick: async () => {
      try {
        await deleteFile(filename)
        notification.success({ title: '已删除', duration: 2000 })
        emit('refresh')
      } catch (err) {
        notification.error({ title: '删除失败', content: err instanceof Error ? err.message : '未知错误', duration: 4000 })
      }
    },
  })
}

// ── 下载 ────────────────────────────────────────
async function handleDownload(filename: string) {
  try {
    await downloadFile(filename)
  } catch (err) {
    notification.error({ title: '下载失败', content: err instanceof Error ? err.message : '未知错误', duration: 4000 })
  }
}

// ── 工具函数 ─────────────────────────────────────
function formatSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / 1024 / 1024).toFixed(2)} MB`
}

function formatTime(ts: number): string {
  return new Date(ts * 1000).toLocaleString('zh-CN')
}

// ── 列定义 ───────────────────────────────────────
function handleFilenameClick(filename: string) {
  if (filename.toLowerCase().endsWith('.md')) {
    previewFilename.value = filename
    previewVisible.value = true
  } else {
    notification.warning({
      title: '暂不支持预览',
      content: `"${filename}" 暂不支持在线预览，请下载后查看`,
      duration: 3000,
    })
  }
}

const columns: DataTableColumns<FileInfo> = [
  {
    title: '文件名',
    key: 'name',
    ellipsis: { tooltip: true },
    render: (row) => {
      const isMd = row.name.toLowerCase().endsWith('.md')
      return h(
        NButton,
        {
          text: true,
          type: isMd ? 'primary' : 'default',
          style: 'font-size:13px; max-width:100%; overflow:hidden; text-overflow:ellipsis',
          onClick: () => handleFilenameClick(row.name),
        },
        { default: () => row.name },
      )
    },
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
    width: 200,
    render: (row) =>
      h('div', { style: 'display:flex;gap:6px' }, [
        h(NButton, { size: 'small', type: 'primary', ghost: true, onClick: () => handleDownload(row.name) }, { default: () => '下载' }),
        h(NButton, { size: 'small', ghost: true, onClick: () => openRename(row.name) }, { default: () => '重命名' }),
        h(NButton, { size: 'small', type: 'error', ghost: true, onClick: () => openDelete(row.name) }, { default: () => '删除' }),
      ]),
  },
]
</script>

<template>
  <div class="upload-zone">
    <n-upload
      multiple
      :custom-request="handleUpload"
      :show-file-list="true"
      list-type="text"
      @finish="onFinish"
    >
      <n-upload-dragger>
        <div style="margin-bottom: 12px">
          <Icon icon="carbon:cloud-upload" width="48" style="opacity: 0.6" />
        </div>
        <n-text style="font-size: 16px">点击或拖拽文件到此区域上传</n-text>
        <n-p depth="3" style="margin: 8px 0 0 0; font-size: 13px">支持任意文件类型</n-p>
      </n-upload-dragger>
    </n-upload>
  </div>
</template>

<script setup lang="ts">
import { NUpload, NUploadDragger, NText, NP, useNotification } from 'naive-ui'
import { Icon } from '@iconify/vue'
import { uploadFile } from '@/api/files'
import type { UploadCustomRequestOptions } from 'naive-ui'

const emit = defineEmits<{ uploaded: [] }>()
const notification = useNotification()

async function handleUpload({ file, onFinish, onError, onProgress }: UploadCustomRequestOptions) {
  try {
    await uploadFile(file.file as File, (percent) => {
      onProgress({ percent })
    })
    onFinish()
  } catch (err) {
    notification.error({
      title: '上传失败',
      content: err instanceof Error ? err.message : '未知错误',
      duration: 4000,
    })
    onError()
  }
}

function onFinish() {
  emit('uploaded')
}
</script>

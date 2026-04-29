<template>
  <div class="files-page">
    <n-space vertical :size="16">
      <UploadZone @uploaded="filesStore.fetchFiles" />
      <n-card title="文件列表">
        <template #header-extra>
          <n-button size="small" quaternary :loading="filesStore.loading" @click="filesStore.fetchFiles">
            <template #icon><Icon icon="carbon:renew" /></template>
            刷新
          </n-button>
        </template>
        <FileList :files="filesStore.files" :loading="filesStore.loading" />
      </n-card>
    </n-space>
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { NSpace, NCard, NButton } from 'naive-ui'
import { Icon } from '@iconify/vue'
import UploadZone from './components/UploadZone.vue'
import FileList from './components/FileList.vue'
import { useFilesStore } from './store'

const filesStore = useFilesStore()

onMounted(() => {
  filesStore.fetchFiles()
})
</script>

<template>
  <n-modal
    :show="show"
    preset="card"
    title="分享到朋友圈"
    style="width: 360px"
    :mask-closable="step !== 'capturing' && step !== 'uploading'"
    @update:show="emit('update:show', $event)"
  >
    <!-- 截图 / 上传中 -->
    <div v-if="step === 'capturing' || step === 'uploading'" class="center-box">
      <n-spin size="large" />
      <n-text depth="3" style="margin-top: 16px">
        {{ step === 'capturing' ? '正在截取对话内容...' : '正在上传图片...' }}
      </n-text>
    </div>

    <!-- 二维码 -->
    <div v-else-if="step === 'done'" class="center-box">
      <n-alert
        v-if="isLocalhost"
        type="warning"
        title="本地环境提示"
        style="margin-bottom: 16px; text-align: left"
      >
        当前地址为 localhost，手机扫码后无法访问。<br>
        部署到公网后分享功能可正常使用。
      </n-alert>
      <canvas ref="qrcanvasRef" style="border-radius: 8px" />
      <n-text style="font-weight: 600; margin-top: 12px">微信扫一扫</n-text>
      <n-text depth="3" style="font-size: 13px; text-align: center; line-height: 1.7">
        扫码后长按图片 → 保存到相册<br>打开微信发布朋友圈时选择该图片
      </n-text>
      <n-button size="small" style="margin-top: 8px" @click="doShare">重新生成</n-button>
    </div>

    <!-- 错误 -->
    <div v-else-if="step === 'error'" class="center-box">
      <n-result status="error" title="生成失败" :description="errorMsg" style="padding: 0">
        <template #footer>
          <n-button @click="doShare">重试</n-button>
        </template>
      </n-result>
    </div>
  </n-modal>
</template>

<script setup lang="ts">
import { ref, watch, nextTick, computed } from 'vue'
import { NModal, NSpin, NText, NButton, NAlert, NResult } from 'naive-ui'
import html2canvas from 'html2canvas'
import QRCode from 'qrcode'
import { uploadShare } from '@/api/share'

const props = defineProps<{
  show: boolean
  messageListEl: HTMLElement | null
}>()

const emit = defineEmits<{
  'update:show': [value: boolean]
}>()

type Step = 'idle' | 'capturing' | 'uploading' | 'done' | 'error'

const step = ref<Step>('idle')
const errorMsg = ref('')
const qrcanvasRef = ref<HTMLCanvasElement | null>(null)

const isLocalhost = computed(() =>
  ['localhost', '127.0.0.1', '::1'].includes(window.location.hostname),
)

watch(
  () => props.show,
  (val) => {
    if (val && step.value !== 'done') doShare()
  },
)

async function doShare() {
  if (!props.messageListEl) {
    errorMsg.value = '未找到对话内容'
    step.value = 'error'
    return
  }

  errorMsg.value = ''
  step.value = 'capturing'

  try {
    const base64 = await captureFullContent(props.messageListEl)
    step.value = 'uploading'
    const result = await uploadShare(base64)
    step.value = 'done'
    await nextTick()
    if (qrcanvasRef.value) {
      await QRCode.toCanvas(qrcanvasRef.value, result.share_url, {
        width: 220,
        margin: 2,
        color: { dark: '#000000', light: '#ffffff' },
      })
    }
  } catch (e) {
    errorMsg.value = e instanceof Error ? e.message : '生成分享失败，请重试'
    step.value = 'error'
  }
}

async function captureFullContent(el: HTMLElement): Promise<string> {
  // 临时展开滚动容器以截取全部内容
  const prev = {
    overflow: el.style.overflow,
    height: el.style.height,
    maxHeight: el.style.maxHeight,
  }
  el.style.overflow = 'visible'
  el.style.height = el.scrollHeight + 'px'
  el.style.maxHeight = 'none'

  await nextTick()

  try {
    const canvas = await html2canvas(el, {
      useCORS: true,
      allowTaint: false,
      backgroundColor: getComputedStyle(document.body).backgroundColor || '#ffffff',
      scale: Math.min(window.devicePixelRatio || 2, 2),
      scrollX: 0,
      scrollY: 0,
      width: el.scrollWidth,
      height: el.scrollHeight,
      logging: false,
    })
    return canvas.toDataURL('image/png')
  } finally {
    el.style.overflow = prev.overflow
    el.style.height = prev.height
    el.style.maxHeight = prev.maxHeight
  }
}
</script>

<style scoped>
.center-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 16px 0 8px;
  gap: 8px;
}
</style>

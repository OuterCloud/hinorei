import client from './client'
import type { ShareResponse } from '@/types'

export async function uploadShare(base64Image: string): Promise<ShareResponse> {
  const { data } = await client.post<ShareResponse>(
    '/share',
    { image: base64Image },
    { timeout: 60000 },
  )
  return data
}

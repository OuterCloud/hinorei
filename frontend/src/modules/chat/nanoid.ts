// Minimal nanoid-like ID generator (no external dependency)
export function nanoid(size = 21): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
  let result = ''
  const arr = new Uint8Array(size)
  crypto.getRandomValues(arr)
  for (let i = 0; i < size; i++) {
    result += chars[arr[i] % chars.length]
  }
  return result
}

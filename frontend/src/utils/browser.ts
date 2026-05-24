export function supportsFileSave(): boolean {
  return typeof window.showSaveFilePicker === 'function'
}

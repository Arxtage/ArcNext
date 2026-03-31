export function destroyBrowserView(paneId: string): void {
  window.arcnext.browser.destroy(paneId)
}

export function undockBrowserView(paneId: string): Promise<boolean> {
  return window.arcnext.browser.undockPane(paneId)
}

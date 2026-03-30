import { BrowserWindow, WebContents } from 'electron'

export function createBrowserPopupWindow(options: Electron.BrowserWindowConstructorOptions): WebContents {
  const popup = new BrowserWindow({
    show: true,
    autoHideMenuBar: true,
    backgroundColor: '#151515',
    ...options
  })

  if (process.platform !== 'darwin') {
    popup.removeMenu()
  }

  return popup.webContents
}

import { app, BrowserWindow, dialog, ipcMain } from 'electron'
import { autoUpdater } from 'electron-updater'
import { join } from 'path'
import { randomUUID } from 'crypto'
import { setupPTY, killAllPTY } from './pty'
import { setupDirHistory, flushDirHistorySync } from './dirHistory'
import { setupBrowserViewManager, destroyAllBrowserViews, adoptView, releaseView } from './browserViewManager'
import {
  createExternalBrowserWindow,
  createExternalBrowserWindowFromView,
  getExternalShellState,
  listExternalWindows,
  dockExternalWindow,
  closeAllExternalWindows,
  requestDockForShellWebContents,
  setDockRequestHandler
} from './externalBrowserWindows'
import type { BrowserDockedPayload } from '../shared/types'

let mainWindow: BrowserWindow | null = null
let forceQuit = false

function emitDocked(payload: BrowserDockedPayload): void {
  if (!mainWindow || mainWindow.isDestroyed()) return
  mainWindow.webContents.send('browser:docked', payload)
}

function dockExternalWindowIntoWorkspace(windowId: number): BrowserDockedPayload | null {
  const result = dockExternalWindow(windowId)
  if (!result) return null

  const { view, url, title } = result
  const paneId = randomUUID()
  adoptView(paneId, view)

  const payload: BrowserDockedPayload = { paneId, url, title }
  emitDocked(payload)
  return payload
}

function createWindow(): void {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    minWidth: 600,
    minHeight: 400,
    titleBarStyle: 'hiddenInset',
    trafficLightPosition: { x: 16, y: 16 },
    backgroundColor: '#121212',
    webPreferences: {
      preload: join(__dirname, '../preload/preload.js'),
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: false // required for node-pty IPC
    }
  })

  mainWindow.on('close', (e) => {
    if (forceQuit) return

    e.preventDefault()
    dialog
      .showMessageBox(mainWindow!, {
        type: 'question',
        buttons: ['Quit', 'Cancel'],
        defaultId: 1,
        cancelId: 1,
        message: 'Are you sure you want to quit?',
        detail: 'All terminal sessions will be closed.'
      })
      .then(({ response }) => {
        if (response === 0) {
          forceQuit = true
          app.quit()
        }
      })
  })

  setupPTY(mainWindow)
  setupDirHistory()
  setupBrowserViewManager(mainWindow)

  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    createExternalBrowserWindow(url)
    return { action: 'deny' }
  })

  ipcMain.handle('browser:listExternalWindows', () => listExternalWindows())

  ipcMain.handle('browser:dockWindow', (_e, windowId: number) => {
    return dockExternalWindowIntoWorkspace(windowId)
  })

  ipcMain.handle('browser:undock', (_e, paneId: string) => {
    const view = releaseView(paneId)
    if (!view) return false
    createExternalBrowserWindowFromView(view)
    if (mainWindow && !mainWindow.isDestroyed()) {
      mainWindow.webContents.send('browser:undocked', { paneId })
    }
    return true
  })

  ipcMain.handle('externalBrowser:getState', (event) => {
    return getExternalShellState(event.sender)
  })

  ipcMain.on('externalBrowser:dockCurrentWindow', (event) => {
    requestDockForShellWebContents(event.sender)
  })

  // Handle native dock requests from external window menu/shortcut.
  setDockRequestHandler((windowId: number) => {
    dockExternalWindowIntoWorkspace(windowId)
  })

  ipcMain.on('sidebar:traffic-lights', (_e, visible: boolean) => {
    mainWindow?.setWindowButtonVisibility(visible)
  })

  if (process.env.ELECTRON_RENDERER_URL) {
    mainWindow.loadURL(process.env.ELECTRON_RENDERER_URL)
  } else {
    mainWindow.loadFile(join(__dirname, '../renderer/index.html'))
  }
}

app.whenReady().then(() => {
  createWindow()
  autoUpdater.checkForUpdatesAndNotify()
})

autoUpdater.on('update-downloaded', (info) => {
  dialog
    .showMessageBox({
      type: 'info',
      title: 'Update Ready',
      message: `v${info.version} has been downloaded. Restart to apply it.`,
      buttons: ['Restart', 'Later']
    })
    .then(({ response }) => {
      if (response === 0) {
        forceQuit = true
        autoUpdater.quitAndInstall()
      }
    })
})

app.on('before-quit', (e) => {
  if (!forceQuit) {
    e.preventDefault()
    return
  }
  killAllPTY()
  destroyAllBrowserViews()
  closeAllExternalWindows()
  flushDirHistorySync()
})

app.on('window-all-closed', () => {
  app.quit()
})

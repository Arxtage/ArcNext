import { app, BrowserWindow, Menu, WebContents, WebContentsView } from 'electron'
import { join } from 'path'
import type { ExternalBrowserShellState, ExternalBrowserWindowInfo } from '../shared/types'
import { createBrowserView, wireBrowserViewEvents } from './browserViewUtils'

const EXTERNAL_SHELL_TOOLBAR_HEIGHT = 46

interface TrackedWindow {
  shell: BrowserWindow
  view: WebContentsView
  state: ExternalBrowserWindowInfo
  cleanupViewEvents: (() => void) | null
}

const windows = new Map<number, TrackedWindow>()

let onDockRequest: ((windowId: number) => void) | null = null

export function setDockRequestHandler(handler: (windowId: number) => void): void {
  onDockRequest = handler
}

function isDockShortcut(input: Electron.Input): boolean {
  return (input.meta || input.control) && input.shift && input.key.toLowerCase() === 'd'
}

function buildExternalWindowMenu(windowId: number): Menu {
  const makeDockMenuItem = () => ({
    label: 'Dock to ArcNext',
    accelerator: 'CmdOrCtrl+Shift+D',
    click: () => {
      onDockRequest?.(windowId)
    }
  })

  const editMenu = {
    label: 'Edit',
    submenu: [
      { role: 'undo' as const },
      { role: 'redo' as const },
      { type: 'separator' as const },
      { role: 'cut' as const },
      { role: 'copy' as const },
      { role: 'paste' as const },
      { role: 'selectAll' as const }
    ]
  }

  const viewMenu = {
    label: 'View',
    submenu: [
      { role: 'reload' as const },
      { role: 'forceReload' as const },
      { role: 'toggleDevTools' as const }
    ]
  }

  const windowMenu = {
    label: 'Window',
    submenu: [
      makeDockMenuItem(),
      { type: 'separator' as const },
      { role: 'minimize' as const },
      ...(process.platform === 'darwin'
        ? [{ role: 'zoom' as const }, { type: 'separator' as const }, { role: 'front' as const }]
        : [{ role: 'close' as const }])
    ]
  }

  const template = process.platform === 'darwin'
    ? [
        {
          label: app.name,
          submenu: [
            { role: 'about' as const },
            { type: 'separator' as const },
            { role: 'services' as const },
            { type: 'separator' as const },
            { role: 'hide' as const },
            { role: 'hideOthers' as const },
            { role: 'unhide' as const },
            { type: 'separator' as const },
            { role: 'quit' as const }
          ]
        },
        editMenu,
        viewMenu,
        windowMenu
      ]
    : [
        {
          label: 'File',
          submenu: [makeDockMenuItem(), { type: 'separator' as const }, { role: 'close' as const }]
        },
        editMenu,
        viewMenu,
        windowMenu
      ]

  return Menu.buildFromTemplate(template)
}

function shellStateForTrackedWindow(tracked: TrackedWindow): ExternalBrowserShellState {
  return {
    url: tracked.state.url,
    title: tracked.state.title
  }
}

function publishShellState(tracked: TrackedWindow): void {
  if (tracked.shell.isDestroyed()) return
  tracked.shell.webContents.send('externalBrowser:stateChanged', shellStateForTrackedWindow(tracked))
}

function syncViewBounds(tracked: TrackedWindow): void {
  if (tracked.shell.isDestroyed()) return
  const [width, height] = tracked.shell.getContentSize()
  tracked.view.setBounds({
    x: 0,
    y: EXTERNAL_SHELL_TOOLBAR_HEIGHT,
    width,
    height: Math.max(0, height - EXTERNAL_SHELL_TOOLBAR_HEIGHT)
  })
}

function loadExternalShellPage(shell: BrowserWindow): void {
  if (process.env.ELECTRON_RENDERER_URL) {
    const url = new URL('external-shell.html', `${process.env.ELECTRON_RENDERER_URL}/`).toString()
    shell.loadURL(url)
  } else {
    shell.loadFile(join(__dirname, '../renderer/external-shell.html'))
  }
}

function setupTrackedWindow(tracked: TrackedWindow): void {
  const { shell, state } = tracked

  shell.setMenu(buildExternalWindowMenu(state.id))
  shell.contentView.addChildView(tracked.view)
  syncViewBounds(tracked)
  loadExternalShellPage(shell)

  shell.on('resize', () => syncViewBounds(tracked))
  shell.webContents.on('did-finish-load', () => publishShellState(tracked))
  shell.on('closed', () => {
    const current = windows.get(state.id)
    if (!current) return
    windows.delete(state.id)
    current.cleanupViewEvents?.()
    current.cleanupViewEvents = null
    try { current.view.webContents.close() } catch { /* already closed */ }
  })

  tracked.cleanupViewEvents = wireBrowserViewEvents(tracked.view, {
    onTitle: (title) => {
      tracked.state.title = title
      shell.setTitle(title || tracked.state.url || 'Browser')
      publishShellState(tracked)
    },
    onUrl: (url) => {
      tracked.state.url = url
      publishShellState(tracked)
    },
    onOpenExternal: (url) => {
      createExternalBrowserWindow(url)
    },
    onBeforeInput: (input) => {
      if (!isDockShortcut(input)) return false
      onDockRequest?.(tracked.state.id)
      return true
    }
  })
}

function createShellWindow(): BrowserWindow {
  return new BrowserWindow({
    width: 1000,
    height: 800,
    minWidth: 420,
    minHeight: 320,
    titleBarStyle: 'hiddenInset',
    trafficLightPosition: { x: 16, y: 14 },
    backgroundColor: '#151515',
    webPreferences: {
      preload: join(__dirname, '../preload/externalShellPreload.js'),
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: true
    }
  })
}

function createTrackedWindow(view: WebContentsView, url: string, title: string): TrackedWindow {
  const shell = createShellWindow()
  const state: ExternalBrowserWindowInfo = {
    id: shell.id,
    url,
    title
  }

  const tracked: TrackedWindow = {
    shell,
    view,
    state,
    cleanupViewEvents: null
  }

  windows.set(shell.id, tracked)
  setupTrackedWindow(tracked)
  shell.setTitle(title || url || 'Browser')
  return tracked
}

function detachTrackedWindow(windowId: number): { view: WebContentsView; url: string; title: string } | null {
  const tracked = windows.get(windowId)
  if (!tracked) return null

  tracked.cleanupViewEvents?.()
  tracked.cleanupViewEvents = null

  try { tracked.shell.contentView.removeChildView(tracked.view) } catch { /* already detached */ }

  windows.delete(windowId)

  if (!tracked.shell.isDestroyed()) {
    tracked.shell.destroy()
  }

  return {
    view: tracked.view,
    url: tracked.state.url,
    title: tracked.state.title
  }
}

function trackedWindowForShell(shell: BrowserWindow): TrackedWindow | null {
  for (const tracked of windows.values()) {
    if (tracked.shell === shell) return tracked
  }
  return null
}

export function getExternalShellState(sender: WebContents): ExternalBrowserShellState | null {
  const shell = BrowserWindow.fromWebContents(sender)
  if (!shell) return null
  const tracked = trackedWindowForShell(shell)
  return tracked ? shellStateForTrackedWindow(tracked) : null
}

export function requestDockForShellWebContents(sender: WebContents): boolean {
  const shell = BrowserWindow.fromWebContents(sender)
  if (!shell) return false
  const tracked = trackedWindowForShell(shell)
  if (!tracked) return false
  onDockRequest?.(tracked.state.id)
  return true
}

export function createExternalBrowserWindow(url: string): number {
  const view = createBrowserView()
  const tracked = createTrackedWindow(view, url, '')
  view.webContents.loadURL(url)
  return tracked.state.id
}

export function createExternalBrowserWindowFromView(view: WebContentsView): number {
  const tracked = createTrackedWindow(view, view.webContents.getURL(), view.webContents.getTitle())
  publishShellState(tracked)
  return tracked.state.id
}

export function dockExternalWindow(windowId: number): { view: WebContentsView; url: string; title: string } | null {
  return detachTrackedWindow(windowId)
}

export function listExternalWindows(): ExternalBrowserWindowInfo[] {
  return Array.from(windows.values()).map(({ state }) => ({ ...state }))
}

export function closeAllExternalWindows(): void {
  for (const windowId of Array.from(windows.keys())) {
    const tracked = windows.get(windowId)
    if (!tracked) continue
    windows.delete(windowId)
    tracked.cleanupViewEvents?.()
    tracked.cleanupViewEvents = null
    try { tracked.view.webContents.close() } catch { /* already closed */ }
    try { tracked.shell.close() } catch { /* already closed */ }
  }
}

export function isExternalShell(win: BrowserWindow): number | null {
  for (const [id, tracked] of windows.entries()) {
    if (tracked.shell === win) return id
  }
  return null
}

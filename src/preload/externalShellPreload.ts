import { contextBridge, ipcRenderer, IpcRendererEvent } from 'electron'
import type { ExternalBrowserShellState } from '../shared/types'

const api = {
  getState: (): Promise<ExternalBrowserShellState | null> =>
    ipcRenderer.invoke('externalBrowser:getState'),
  dock: (): void => {
    ipcRenderer.send('externalBrowser:dockCurrentWindow')
  },
  onStateChanged: (cb: (state: ExternalBrowserShellState) => void) => {
    const handler = (_event: IpcRendererEvent, state: ExternalBrowserShellState) => cb(state)
    ipcRenderer.on('externalBrowser:stateChanged', handler)
    return () => { ipcRenderer.removeListener('externalBrowser:stateChanged', handler) }
  }
}

contextBridge.exposeInMainWorld('externalBrowser', api)

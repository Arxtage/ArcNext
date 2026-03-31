import type { ExternalBrowserShellState } from '../shared/types'
import './styles/externalShell.css'

const titleEl = document.getElementById('external-shell-title')
const urlEl = document.getElementById('external-shell-url')
const dockButton = document.getElementById('external-shell-dock') as HTMLButtonElement | null

function applyState(state: ExternalBrowserShellState | null): void {
  if (!titleEl || !urlEl) return

  const title = state?.title?.trim() || 'Loading…'
  const url = state?.url?.trim() || ''

  document.title = title
  titleEl.textContent = title
  urlEl.textContent = url
  urlEl.title = url
}

async function init(): Promise<void> {
  applyState(await window.externalBrowser.getState())
  window.externalBrowser.onStateChanged((state) => applyState(state))

  dockButton?.addEventListener('click', () => {
    dockButton.disabled = true
    dockButton.textContent = 'Docking…'
    window.externalBrowser.dock()
  })
}

void init()

import { Terminal } from '@xterm/xterm'
import { FitAddon } from '@xterm/addon-fit'
import { WebglAddon } from '@xterm/addon-webgl'
import { WebLinksAddon } from '@xterm/addon-web-links'
import '@xterm/xterm/css/xterm.css'
import { useAutocompleteStore } from '../store/autocompleteStore'
import { fuzzyMatch } from '../util/fuzzy'

type TitleCallback = (paneId: string, title: string) => void
type CwdCallback = (paneId: string, cwd: string) => void
let onTitleChange: TitleCallback | null = null
let onCwdChange: CwdCallback | null = null

export function setTitleChangeCallback(cb: TitleCallback): void {
  onTitleChange = cb
}

export function setCwdChangeCallback(cb: CwdCallback): void {
  onCwdChange = cb
}

interface ManagedTerminal {
  term: Terminal
  fit: FitAddon
  webgl: WebglAddon | null
  removeDataListener: () => void
  removeExitListener: () => void
  removeClickCommitListener: () => void
}

const terminals = new Map<string, ManagedTerminal>()

function getCursorPixelPosition(term: Terminal): { x: number; y: number } {
  const screen = term.element?.querySelector('.xterm-screen') as HTMLElement | null
  if (!screen) return { x: 0, y: 0 }
  const rect = screen.getBoundingClientRect()
  const cellWidth = screen.clientWidth / term.cols
  const cellHeight = screen.clientHeight / term.rows
  const cursorX = term.buffer.active.cursorX
  const cursorY = term.buffer.active.cursorY
  return {
    x: rect.left + cursorX * cellWidth,
    y: rect.top + (cursorY + 1) * cellHeight,
  }
}

function handleAutocompleteCommit(paneId: string): void {
  const store = useAutocompleteStore.getState()
  const { entries, query, selectedIndex } = store
  const filtered = query ? entries.filter((e) => fuzzyMatch(e.path, query)) : entries
  const results = filtered.slice(0, 20)
  const match = results[selectedIndex]

  if (match) {
    const escaped = match.path.replace(/'/g, "'\\''")
    window.arcnext.pty.write(paneId, `cd '${escaped}'\n`)
  } else {
    // No match — forward the buffered text
    window.arcnext.pty.write(paneId, '@' + query)
  }
  store.deactivate()
}

function cancelAutocomplete(paneId: string): void {
  const store = useAutocompleteStore.getState()
  const buffered = '@' + store.query
  window.arcnext.pty.write(paneId, buffered)
  store.deactivate()
}

const parkingDiv = document.createElement('div')
parkingDiv.id = 'terminal-parking'
parkingDiv.style.cssText = 'visibility:hidden;position:absolute;width:0;height:0;overflow:hidden'
document.body.appendChild(parkingDiv)

export function createTerminal(paneId: string): Terminal {
  if (terminals.has(paneId)) return terminals.get(paneId)!.term

  const term = new Terminal({
    fontSize: 14,
    fontFamily: "'SF Mono', 'Fira Code', 'JetBrains Mono', monospace",
    theme: {
      background: '#161616',
      foreground: '#e0e0e0',
      cursor: '#e0e0e0',
      selectionBackground: '#3a3a3a',
      black: '#161616',
      red: '#ff6b6b',
      green: '#51cf66',
      yellow: '#ffd43b',
      blue: '#74c0fc',
      magenta: '#cc5de8',
      cyan: '#66d9e8',
      white: '#e0e0e0'
    },
    cursorBlink: true,
    allowProposedApi: true,
    scrollback: 10_000
  })

  const fit = new FitAddon()
  term.loadAddon(fit)
  term.loadAddon(new WebLinksAddon())

  // Open terminal into a parked host div immediately so DOM element always exists
  const host = document.createElement('div')
  host.style.cssText = 'width:100%;height:100%'
  parkingDiv.appendChild(host)
  term.open(host)

  // Load WebGL once — it survives re-parenting because we never detach from the document
  let webgl: WebglAddon | null = null
  try {
    const addon = new WebglAddon()
    term.loadAddon(addon)
    webgl = addon
  } catch {
    // WebGL not available, canvas fallback
  }

  // PTY connection
  window.arcnext.pty.create(paneId)

  // Inline @ autocomplete key interception
  term.attachCustomKeyEventHandler((e: KeyboardEvent) => {
    const store = useAutocompleteStore.getState()
    const isActive = (store.pending || store.active) && store.paneId === paneId

    // Trigger on @ keydown (unmodified, not during autocomplete)
    if (!isActive && e.type === 'keydown' && e.key === '@' && !e.metaKey && !e.ctrlKey && !e.altKey) {
      const cursor = getCursorPixelPosition(term)
      store.startPending(paneId, cursor)

      window.arcnext.dirHistory.query().then((entries: Array<{ path: string; visitCount: number; lastVisit: number; score: number }>) => {
        const s = useAutocompleteStore.getState()
        // Only activate if still pending for this pane
        if (s.pending && s.paneId === paneId) {
          if (entries.length === 0) {
            // No history — cancel and forward @
            window.arcnext.pty.write(paneId, '@' + s.query)
            s.deactivate()
          } else {
            s.activate(entries)
          }
        }
      })
      return false
    }

    if (!isActive) return true

    // Only handle keydown events while autocomplete is active
    if (e.type !== 'keydown') return false

    // Modified keys (Cmd/Ctrl/Alt combos) — cancel autocomplete and let key through
    if (e.metaKey || e.ctrlKey || e.altKey) {
      cancelAutocomplete(paneId)
      return true
    }

    switch (e.key) {
      case 'ArrowUp':
        store.setSelectedIndex(Math.max(store.selectedIndex - 1, 0))
        return false
      case 'ArrowDown': {
        const filtered = store.query
          ? store.entries.filter((en) => fuzzyMatch(en.path, store.query))
          : store.entries
        const maxIdx = Math.min(filtered.length, 20) - 1
        store.setSelectedIndex(Math.min(store.selectedIndex + 1, maxIdx))
        return false
      }
      case 'Enter':
      case 'Tab':
        handleAutocompleteCommit(paneId)
        return false
      case 'Escape':
        cancelAutocomplete(paneId)
        return false
      case 'Backspace':
        if (store.query.length === 0) {
          cancelAutocomplete(paneId)
        } else {
          store.setQuery(store.query.slice(0, -1))
        }
        return false
      default:
        // Single printable character
        if (e.key.length === 1) {
          store.appendToQuery(e.key)
          return false
        }
        // Non-printable special key — cancel
        cancelAutocomplete(paneId)
        return true
    }
  })

  // Listen for click-to-commit events from InlineAutocomplete component
  const handleClickCommit = () => {
    const store = useAutocompleteStore.getState()
    if (store.active && store.paneId === paneId) {
      handleAutocompleteCommit(paneId)
    }
  }
  window.addEventListener('inline-ac-commit', handleClickCommit)

  term.onData((data) => {
    // Swallow input while autocomplete is active for this pane
    const store = useAutocompleteStore.getState()
    if ((store.active || store.pending) && store.paneId === paneId) return
    window.arcnext.pty.write(paneId, data)
  })

  const removeDataListener = window.arcnext.pty.onData((id, data) => {
    if (id === paneId) term.write(data)
  })

  const removeExitListener = window.arcnext.pty.onExit((id, code) => {
    if (id === paneId) term.write(`\r\n[process exited with code ${code}]`)
  })

  term.onResize(({ cols, rows }) => {
    window.arcnext.pty.resize(paneId, cols, rows)
  })

  term.onTitleChange((title) => {
    onTitleChange?.(paneId, title)
  })

  term.parser.registerOscHandler(7, (data) => {
    try {
      const url = new URL(data)
      const cwd = decodeURIComponent(url.pathname)
      if (cwd) onCwdChange?.(paneId, cwd)
    } catch {
      // malformed OSC 7, ignore
    }
    return true
  })

  const removeClickCommitListener = () => window.removeEventListener('inline-ac-commit', handleClickCommit)

  terminals.set(paneId, { term, fit, webgl, removeDataListener, removeExitListener, removeClickCommitListener })
  return term
}

function safeFit(managed: ManagedTerminal): void {
  const host = managed.term.element?.parentElement
  if (!host || host.clientWidth < 20 || host.clientHeight < 20) return
  managed.fit.fit()
}

/** Attach a terminal to a DOM element. Call this when the component mounts. */
export function attachTerminal(paneId: string, container: HTMLElement): void {
  const managed = terminals.get(paneId)
  if (!managed) return

  const host = managed.term.element?.parentElement
  if (!host) return

  // Already in the target container — just refit
  if (host.parentElement === container) {
    safeFit(managed)
    return
  }

  // Clear any stale DOM from this container before attaching
  while (container.firstChild) {
    container.removeChild(container.firstChild)
  }

  // Move host div from parking (or previous container) into new container
  container.appendChild(host)
  safeFit(managed)
}

/** Detach terminal back to parking div. Call this when the component unmounts. */
export function detachTerminal(paneId: string): void {
  const managed = terminals.get(paneId)
  if (!managed) return
  const host = managed.term.element?.parentElement
  if (host && host.parentElement !== parkingDiv) {
    parkingDiv.appendChild(host)
  }
}

/** Refit the terminal to its container size */
export function fitTerminal(paneId: string): void {
  const managed = terminals.get(paneId)
  if (managed) safeFit(managed)
}

/** Focus the terminal */
export function focusTerminal(paneId: string): void {
  terminals.get(paneId)?.term.focus()
}

/** Write data directly to the PTY (for sending escape sequences) */
export function writeToTerminalPTY(paneId: string, data: string): void {
  window.arcnext.pty.write(paneId, data)
}

/** Destroy the terminal and kill its PTY. Only call on explicit user close. */
export function destroyTerminal(paneId: string): void {
  const managed = terminals.get(paneId)
  if (!managed) return
  managed.removeDataListener()
  managed.removeExitListener()
  managed.removeClickCommitListener()
  // Clean up host div from parking to prevent DOM leaks
  const host = managed.term.element?.parentElement
  if (host) host.remove()
  // Dispose addons before terminal
  if (managed.webgl) managed.webgl.dispose()
  window.arcnext.pty.kill(paneId)
  managed.term.dispose()
  terminals.delete(paneId)
}

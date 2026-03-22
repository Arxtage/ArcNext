import { useState, useEffect, useRef, useCallback, useMemo, type ReactNode } from 'react'
import { writeToTerminalPTY, focusTerminal } from '../model/terminalManager'
import { usePaneStore, useActiveWorkspace, type BrowserPaneInfo } from '../store/paneStore'
import { allPaneIds } from '../model/splitTree'
import type { DirEntry, WebEntry } from '../../shared/types'
import {
  normalizeUrl,
  ensureProtocol,
  hostnameFromUrl,
  bareUrl,
  compactUrl,
  looksLikeUrl
} from '../../shared/urlUtils'

type PickerItemType = 'dir' | 'web' | 'web-open' | 'web-switch' | 'web-open-new'

interface PickerItem {
  type: PickerItemType
  key: string
  label: string        // text used for ghost text completion
  displayName: string  // what to show in the list
  score: number
  dirPath?: string
  url?: string
  title?: string
  faviconUrl?: string
  switchWorkspaceId?: string
  switchWorkspaceName?: string
}

interface Props {
  onClose: () => void
}

function substringMatch(text: string, query: string): number {
  return text.toLowerCase().indexOf(query.toLowerCase())
}

function highlightSubstring(text: string, query: string): ReactNode {
  if (!query) return text
  const idx = text.toLowerCase().indexOf(query.toLowerCase())
  if (idx === -1) return text
  return (
    <>
      {text.slice(0, idx)}
      <mark>{text.slice(idx, idx + query.length)}</mark>
      {text.slice(idx + query.length)}
    </>
  )
}

function computeGhostText(item: PickerItem, query: string): string {
  if (!query) return ''
  const idx = item.label.toLowerCase().indexOf(query.toLowerCase())
  if (idx === -1) return ''
  return item.label.slice(idx + query.length)
}

const DIR_BOOST = 1.5

export default function UnifiedPicker({ onClose }: Props) {
  const [query, setQuery] = useState('')
  const [allDirEntries, setAllDirEntries] = useState<DirEntry[]>([])
  const [allWebEntries, setAllWebEntries] = useState<WebEntry[]>([])
  const [selectedIndex, setSelectedIndex] = useState(0)
  const inputRef = useRef<HTMLInputElement>(null)
  const resultsRef = useRef<HTMLDivElement>(null)
  const ws = useActiveWorkspace()
  const panes = usePaneStore((s) => s.panes)
  const workspaces = usePaneStore((s) => s.workspaces)
  const addBrowserWorkspace = usePaneStore((s) => s.addBrowserWorkspace)
  const switchWorkspace = usePaneStore((s) => s.switchWorkspace)

  useEffect(() => {
    inputRef.current?.focus()
    Promise.all([
      window.arcnext.dirHistory.query(),
      window.arcnext.webHistory.query()
    ]).then(([dirs, webs]) => {
      setAllDirEntries(dirs)
      setAllWebEntries(webs)
    })
  }, [])

  // --- Memoized data pipeline ---

  const sortedDirs = useMemo(() => {
    const items: PickerItem[] = (query
      ? allDirEntries.filter((e) => substringMatch(e.path, query) !== -1)
      : allDirEntries
    ).map((e) => {
      const name = e.path.split('/').filter(Boolean).pop() || e.path
      return {
        type: 'dir' as const,
        key: `dir:${e.path}`,
        label: name,
        displayName: name,
        score: e.score * DIR_BOOST,
        dirPath: e.path
      }
    })
    const limit = query ? 15 : 4
    return items.sort((a, b) => b.score - a.score).slice(0, limit)
  }, [query, allDirEntries])

  const sortedWebs = useMemo(() => {
    const filtered = query
      ? allWebEntries.filter((e) =>
          substringMatch(e.url, query) !== -1 ||
          (e.title && substringMatch(e.title, query) !== -1)
        )
      : allWebEntries

    const dedupMap = new Map<string, (typeof filtered)[0]>()
    for (const e of filtered) {
      const k = (e.title || e.url).toLowerCase()
      const existing = dedupMap.get(k)
      if (!existing || e.score > existing.score) dedupMap.set(k, e)
    }

    const items: PickerItem[] = [...dedupMap.values()].map((e) => ({
      type: 'web' as const,
      key: `web:${e.url}`,
      label: bareUrl(e.url),
      displayName: e.title || hostnameFromUrl(e.url),
      score: e.score,
      url: e.url,
      title: e.title,
      faviconUrl: e.faviconUrl
    }))
    const limit = query ? 15 : 4
    return items.sort((a, b) => b.score - a.score).slice(0, limit)
  }, [query, allWebEntries])

  const openBrowserPanes = useMemo(() => {
    const result: Array<{ paneId: string; url: string; workspaceId: string; workspaceName: string }> = []
    for (const w of workspaces) {
      for (const pid of allPaneIds(w.tree)) {
        const pane = panes.get(pid)
        if (pane?.type === 'browser') {
          const bp = pane as BrowserPaneInfo
          result.push({
            paneId: pid,
            url: bp.url,
            workspaceId: w.id,
            workspaceName: w.name || bp.title || hostnameFromUrl(bp.url)
          })
        }
      }
    }
    return result
  }, [workspaces, panes])

  const directUrlItems = useMemo(() => {
    const items: PickerItem[] = []
    if (!query || !looksLikeUrl(query)) return items

    const targetUrl = ensureProtocol(query)
    const normalizedTarget = normalizeUrl(targetUrl)
    const match = openBrowserPanes.find(
      (p) => normalizeUrl(p.url) === normalizedTarget
    )
    const bareTarget = bareUrl(targetUrl)

    if (match) {
      items.push({
        type: 'web-switch',
        key: `switch:${match.workspaceId}`,
        label: bareTarget,
        displayName: `Switch to "${match.workspaceName}"`,
        score: Infinity,
        url: targetUrl,
        title: `Switch to "${match.workspaceName}"`,
        switchWorkspaceId: match.workspaceId,
        switchWorkspaceName: match.workspaceName
      })
      items.push({
        type: 'web-open-new',
        key: `open-new:${targetUrl}`,
        label: bareTarget,
        displayName: 'Open in new workspace',
        score: Infinity,
        url: targetUrl,
        title: 'Open in new workspace'
      })
    } else {
      items.push({
        type: 'web-open',
        key: `open:${targetUrl}`,
        label: bareTarget,
        displayName: `Open ${query}`,
        score: Infinity,
        url: targetUrl,
        title: `Open ${query}`
      })
    }
    return items
  }, [query, openBrowserPanes])

  const allItems = useMemo(
    () => [...sortedDirs, ...directUrlItems, ...sortedWebs],
    [sortedDirs, directUrlItems, sortedWebs]
  )

  // Section offsets for flat indexing
  const dirOffset = 0
  const directUrlOffset = sortedDirs.length
  const webOffset = directUrlOffset + directUrlItems.length

  const ghostText = (() => {
    if (!query) return ''
    const item = allItems[selectedIndex]
    if (!item) return ''
    return computeGhostText(item, query)
  })()

  useEffect(() => { setSelectedIndex(0) }, [query])

  useEffect(() => {
    const container = resultsRef.current
    if (!container) return
    const selectables = container.querySelectorAll('[data-selectable]')
    const item = selectables[selectedIndex] as HTMLElement | undefined
    item?.scrollIntoView({ block: 'nearest' })
  }, [selectedIndex])

  const selectDir = useCallback((path: string) => {
    if (!ws) return
    const escaped = path.replace(/'/g, "'\\''")
    writeToTerminalPTY(ws.activePaneId, `cd '${escaped}'\n`)
    onClose()
    setTimeout(() => focusTerminal(ws.activePaneId), 0)
  }, [ws, onClose])

  const selectWeb = useCallback((url: string) => {
    addBrowserWorkspace(ensureProtocol(url))
    onClose()
  }, [addBrowserWorkspace, onClose])

  const selectSwitch = useCallback((workspaceId: string) => {
    switchWorkspace(workspaceId)
    onClose()
  }, [switchWorkspace, onClose])

  const handleSelect = useCallback((item: PickerItem) => {
    switch (item.type) {
      case 'dir':
        if (item.dirPath) selectDir(item.dirPath)
        break
      case 'web':
      case 'web-open':
      case 'web-open-new':
        if (item.url) selectWeb(item.url)
        break
      case 'web-switch':
        if (item.switchWorkspaceId) selectSwitch(item.switchWorkspaceId)
        break
    }
  }, [selectDir, selectWeb, selectSwitch])

  const acceptGhost = useCallback(() => {
    if (!ghostText) return false
    const item = allItems[selectedIndex]
    if (!item) return false
    setQuery(item.label)
    return true
  }, [ghostText, allItems, selectedIndex])

  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    switch (e.key) {
      case 'Escape':
        e.preventDefault()
        onClose()
        if (ws) setTimeout(() => focusTerminal(ws.activePaneId), 0)
        break
      case 'Tab':
        e.preventDefault()
        acceptGhost()
        break
      case 'ArrowRight': {
        const input = inputRef.current
        if (input && input.selectionStart === input.value.length && ghostText) {
          e.preventDefault()
          acceptGhost()
        }
        break
      }
      case 'ArrowDown':
        e.preventDefault()
        setSelectedIndex((i) => Math.min(i + 1, allItems.length - 1))
        break
      case 'ArrowUp':
        e.preventDefault()
        setSelectedIndex((i) => Math.max(i - 1, 0))
        break
      case 'Enter':
        e.preventDefault()
        if (allItems[selectedIndex]) handleSelect(allItems[selectedIndex])
        break
    }
  }, [allItems, selectedIndex, handleSelect, onClose, ws, acceptGhost, ghostText])

  return (
    <div className="picker-overlay" onClick={onClose}>
      <div className="picker" onClick={(e) => e.stopPropagation()}>
        <div className="picker-input-wrapper">
          <div className="picker-ghost" aria-hidden="true">
            <span className="picker-ghost-hidden">{query}</span>
            <span className="picker-ghost-completion">{ghostText}</span>
          </div>
          <input
            ref={inputRef}
            className="picker-input"
            placeholder="Go to directory or website..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={handleKeyDown}
          />
        </div>
        <div className="picker-results" ref={resultsRef}>
          {sortedDirs.length > 0 && (
            <>
              <div className="picker-section-header">dirs</div>
              {sortedDirs.map((item, i) => {
                const idx = dirOffset + i
                return (
                  <div
                    key={item.key}
                    data-selectable
                    className={`picker-item${idx === selectedIndex ? ' selected' : ''}`}
                    onClick={() => handleSelect(item)}
                    onMouseEnter={() => setSelectedIndex(idx)}
                  >
                    <span className="picker-item-name">{highlightSubstring(item.displayName, query)}</span>
                    <span className="picker-item-path">{highlightSubstring(item.dirPath!, query)}</span>
                  </div>
                )
              })}
            </>
          )}

          {(directUrlItems.length > 0 || sortedWebs.length > 0) && (
            <>
              {sortedDirs.length > 0 && <div className="picker-section-divider" />}
              <div className="picker-section-header">web</div>

              {directUrlItems.map((item, i) => {
                const idx = directUrlOffset + i
                return (
                  <div
                    key={item.key}
                    data-selectable
                    className={`picker-item${idx === selectedIndex ? ' selected' : ''}`}
                    onClick={() => handleSelect(item)}
                    onMouseEnter={() => setSelectedIndex(idx)}
                  >
                    <div className="picker-item-web-row">
                      <span className="picker-item-favicon-icon">{'\u{1F310}'}</span>
                      <span className="picker-item-name">{item.displayName}</span>
                      {item.type === 'web-switch' && (
                        <span className="picker-item-badge">open</span>
                      )}
                    </div>
                  </div>
                )
              })}

              {sortedWebs.map((item, i) => {
                const idx = webOffset + i
                return (
                  <div
                    key={item.key}
                    data-selectable
                    className={`picker-item picker-item-compact${idx === selectedIndex ? ' selected' : ''}`}
                    onClick={() => handleSelect(item)}
                    onMouseEnter={() => setSelectedIndex(idx)}
                  >
                    <div className="picker-item-web-row">
                      {item.faviconUrl ? (
                        <img
                          className="picker-item-favicon"
                          src={item.faviconUrl}
                          alt=""
                          onError={(e) => { (e.target as HTMLImageElement).style.display = 'none' }}
                        />
                      ) : (
                        <span className="picker-item-favicon-icon">{'\u{1F310}'}</span>
                      )}
                      <span className="picker-item-name picker-item-name-truncate">{highlightSubstring(item.displayName, query)}</span>
                      <span className="picker-item-url-compact">{compactUrl(item.url!)}</span>
                    </div>
                  </div>
                )
              })}
            </>
          )}

          {allItems.length === 0 && query && (
            <div className="picker-empty">No matching results</div>
          )}
          {allItems.length === 0 && !query && (
            <div className="picker-empty">No history yet</div>
          )}
        </div>
      </div>
    </div>
  )
}

import { useEffect, useRef, useMemo } from 'react'
import { useAutocompleteStore } from '../store/autocompleteStore'
import { fuzzyMatch, highlightMatch } from '../util/fuzzy'

export default function InlineAutocomplete() {
  const active = useAutocompleteStore((s) => s.active)
  const query = useAutocompleteStore((s) => s.query)
  const cursorPixel = useAutocompleteStore((s) => s.cursorPixel)
  const entries = useAutocompleteStore((s) => s.entries)
  const selectedIndex = useAutocompleteStore((s) => s.selectedIndex)
  const setSelectedIndex = useAutocompleteStore((s) => s.setSelectedIndex)
  const resultsRef = useRef<HTMLDivElement>(null)

  const filtered = useMemo(() => {
    if (!query) return entries
    return entries.filter((e) => fuzzyMatch(e.path, query))
  }, [entries, query])

  const results = filtered.slice(0, 20)

  // Scroll selected item into view
  useEffect(() => {
    const container = resultsRef.current
    if (!container) return
    const item = container.children[selectedIndex] as HTMLElement | undefined
    item?.scrollIntoView({ block: 'nearest' })
  }, [selectedIndex])

  if (!active || results.length === 0) return null

  // Clamp position to viewport
  const dropdownWidth = 400
  const dropdownMaxHeight = 280
  const x = Math.min(cursorPixel.x, window.innerWidth - dropdownWidth - 8)
  const yBelow = cursorPixel.y
  const yAbove = cursorPixel.y - dropdownMaxHeight
  // Prefer below cursor, flip above if not enough space
  const y = yBelow + dropdownMaxHeight > window.innerHeight ? Math.max(yAbove, 4) : yBelow

  return (
    <div
      className="inline-ac"
      style={{ left: x, top: y }}
      onMouseDown={(e) => e.preventDefault()}
    >
      <div className="inline-ac-header">@{query}</div>
      <div className="inline-ac-results" ref={resultsRef}>
        {results.map((entry, i) => {
          const name = entry.path.split('/').filter(Boolean).pop() || entry.path
          return (
            <div
              key={entry.path}
              className={`inline-ac-item${i === selectedIndex ? ' selected' : ''}`}
              onMouseDown={(e) => {
                e.preventDefault()
                // Simulate commit by dispatching Enter via the store's selected index
                setSelectedIndex(i)
                // The actual commit is handled by terminalManager's key handler
                // Clicking sets index; user can then press Enter, or we commit directly
                // For click-to-select, we trigger commit via a custom event
                window.dispatchEvent(new CustomEvent('inline-ac-commit'))
              }}
              onMouseEnter={() => setSelectedIndex(i)}
            >
              <span className="inline-ac-name">{highlightMatch(name, query)}</span>
              <span className="inline-ac-path">{highlightMatch(entry.path, query)}</span>
            </div>
          )
        })}
      </div>
    </div>
  )
}

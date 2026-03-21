import { useEffect, useRef } from 'react'

interface Props {
  searchTerm: string
  onSearchChange: (term: string) => void
  onNext: () => void
  onPrev: () => void
  onClose: () => void
  activeMatch?: number
  totalMatches?: number
}

export default function FindBar({ searchTerm, onSearchChange, onNext, onPrev, onClose, activeMatch, totalMatches }: Props) {
  const inputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    inputRef.current?.focus()
    inputRef.current?.select()
  }, [])

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Escape') { onClose(); return }
    if (e.key === 'Enter') {
      e.preventDefault()
      e.shiftKey ? onPrev() : onNext()
      return
    }
    e.stopPropagation()
  }

  const countLabel = totalMatches != null
    ? totalMatches === 0 && searchTerm ? 'No matches' : `${activeMatch ?? 0}/${totalMatches}`
    : null

  return (
    <div className="find-bar">
      <input
        data-suppress-shortcuts
        ref={inputRef}
        className="find-bar-input"
        type="text"
        placeholder="Find..."
        value={searchTerm}
        onChange={(e) => onSearchChange(e.target.value)}
        onKeyDown={handleKeyDown}
        spellCheck={false}
      />
      {countLabel && <span className="find-bar-count">{countLabel}</span>}
      <button className="find-bar-btn" onClick={onPrev} title="Previous (Shift+Enter)">&#8249;</button>
      <button className="find-bar-btn" onClick={onNext} title="Next (Enter)">&#8250;</button>
      <button className="find-bar-btn" onClick={onClose} title="Close (Escape)">&times;</button>
    </div>
  )
}

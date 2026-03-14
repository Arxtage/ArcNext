import { useEffect } from 'react'
import SplitView from './components/SplitView'
import { usePaneStore } from './store/paneStore'

export default function App() {
  const tree = usePaneStore((s) => s.tree)
  const splitActive = usePaneStore((s) => s.splitActive)
  const closePane = usePaneStore((s) => s.closePane)
  const activePaneId = usePaneStore((s) => s.activePaneId)
  const focusNext = usePaneStore((s) => s.focusNext)
  const focusPrev = usePaneStore((s) => s.focusPrev)

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      const meta = e.metaKey

      // Cmd+D — split right
      if (meta && !e.shiftKey && e.key === 'd') {
        e.preventDefault()
        splitActive('horizontal')
        return
      }
      // Cmd+Shift+D — split down
      if (meta && e.shiftKey && e.key === 'D') {
        e.preventDefault()
        splitActive('vertical')
        return
      }
      // Cmd+W — close pane
      if (meta && e.key === 'w') {
        e.preventDefault()
        closePane(activePaneId)
        return
      }
      // Cmd+] — next pane
      if (meta && e.key === ']') {
        e.preventDefault()
        focusNext()
        return
      }
      // Cmd+[ — previous pane
      if (meta && e.key === '[') {
        e.preventDefault()
        focusPrev()
        return
      }
    }

    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [splitActive, closePane, activePaneId, focusNext, focusPrev])

  return (
    <div id="app">
      <div id="workspace">
        <SplitView node={tree} />
      </div>
    </div>
  )
}

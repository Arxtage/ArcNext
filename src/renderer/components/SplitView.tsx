import { useCallback, useRef } from 'react'
import { SplitNode } from '../model/splitTree'
import { usePaneStore } from '../store/paneStore'
import TerminalPane from './TerminalPane'

interface Props {
  node: SplitNode
}

export default function SplitView({ node }: Props) {
  if (node.type === 'leaf') {
    return <TerminalPane paneId={node.paneId} />
  }

  const isHorizontal = node.direction === 'horizontal'

  return (
    <div className={`split-container ${isHorizontal ? 'horizontal' : 'vertical'}`}>
      <div className="split-child" style={{ flexBasis: `${node.ratio * 100}%` }}>
        <SplitView node={node.first} />
      </div>
      <Divider
        direction={node.direction}
        firstPaneId={getFirstLeafId(node.first)}
      />
      <div className="split-child" style={{ flexBasis: `${(1 - node.ratio) * 100}%` }}>
        <SplitView node={node.second} />
      </div>
    </div>
  )
}

function getFirstLeafId(node: SplitNode): string {
  if (node.type === 'leaf') return node.paneId
  return getFirstLeafId(node.first)
}

interface DividerProps {
  direction: 'horizontal' | 'vertical'
  firstPaneId: string
}

function Divider({ direction, firstPaneId }: DividerProps) {
  const setTree = usePaneStore((s) => s.setTree)
  const tree = usePaneStore((s) => s.tree)
  const dividerRef = useRef<HTMLDivElement>(null)

  const onMouseDown = useCallback((e: React.MouseEvent) => {
    e.preventDefault()
    const startX = e.clientX
    const startY = e.clientY
    const parent = dividerRef.current?.parentElement
    if (!parent) return

    const parentRect = parent.getBoundingClientRect()

    const onMouseMove = (e: MouseEvent) => {
      const ratio = direction === 'horizontal'
        ? (e.clientX - parentRect.left) / parentRect.width
        : (e.clientY - parentRect.top) / parentRect.height
      const clamped = Math.max(0.1, Math.min(0.9, ratio))
      // Walk tree to find the split containing firstPaneId and update its ratio
      setTree(updateRatio(tree, firstPaneId, clamped))
    }

    const onMouseUp = () => {
      document.removeEventListener('mousemove', onMouseMove)
      document.removeEventListener('mouseup', onMouseUp)
      document.body.style.cursor = ''
      document.body.style.userSelect = ''
    }

    document.body.style.cursor = direction === 'horizontal' ? 'col-resize' : 'row-resize'
    document.body.style.userSelect = 'none'
    document.addEventListener('mousemove', onMouseMove)
    document.addEventListener('mouseup', onMouseUp)
  }, [direction, firstPaneId, tree, setTree])

  return (
    <div
      ref={dividerRef}
      className={`split-divider ${direction}`}
      onMouseDown={onMouseDown}
    />
  )
}

/** Find the split node whose first child contains targetId as its first leaf, and update ratio */
function updateRatio(tree: SplitNode, targetId: string, ratio: number): SplitNode {
  if (tree.type === 'leaf') return tree
  if (getFirstLeafId(tree.first) === targetId) {
    return { ...tree, ratio }
  }
  return {
    ...tree,
    first: updateRatio(tree.first, targetId, ratio),
    second: updateRatio(tree.second, targetId, ratio)
  }
}

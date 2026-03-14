import { create } from 'zustand'
import {
  SplitNode, leaf, splitNode, removeNode, allPaneIds, adjacentPaneId, Direction
} from '../model/splitTree'
import { createTerminal, destroyTerminal } from '../model/terminalManager'

let nextId = 1
function genPaneId(): string {
  return `pane-${nextId++}`
}

export interface PaneInfo {
  id: string
  title: string
  cwd: string
}

interface PaneStore {
  tree: SplitNode
  activePaneId: string
  panes: Map<string, PaneInfo>

  splitActive: (direction: Direction) => void
  closePane: (id: string) => void
  setActive: (id: string) => void
  focusNext: () => void
  focusPrev: () => void
  setPaneTitle: (id: string, title: string) => void
  setTree: (tree: SplitNode) => void
}

function makePane(): PaneInfo {
  const id = genPaneId()
  createTerminal(id)
  return { id, title: 'shell', cwd: '' }
}

const initialPane = makePane()

export const usePaneStore = create<PaneStore>((set, get) => ({
  tree: leaf(initialPane.id),
  activePaneId: initialPane.id,
  panes: new Map([[initialPane.id, initialPane]]),

  splitActive: (direction) => {
    const { tree, activePaneId, panes } = get()
    const newPane = makePane()
    const newPanes = new Map(panes)
    newPanes.set(newPane.id, newPane)
    set({
      tree: splitNode(tree, activePaneId, direction, newPane.id),
      activePaneId: newPane.id,
      panes: newPanes
    })
  },

  closePane: (id) => {
    const { tree, activePaneId, panes } = get()
    const ids = allPaneIds(tree)
    if (ids.length <= 1) return // don't close the last pane

    const newTree = removeNode(tree, id)
    if (!newTree) return

    destroyTerminal(id)

    const newPanes = new Map(panes)
    newPanes.delete(id)

    const newActive = id === activePaneId
      ? adjacentPaneId(tree, id, -1)
      : activePaneId

    set({ tree: newTree, activePaneId: newActive, panes: newPanes })
  },

  setActive: (id) => set({ activePaneId: id }),

  focusNext: () => {
    const { tree, activePaneId } = get()
    set({ activePaneId: adjacentPaneId(tree, activePaneId, 1) })
  },

  focusPrev: () => {
    const { tree, activePaneId } = get()
    set({ activePaneId: adjacentPaneId(tree, activePaneId, -1) })
  },

  setPaneTitle: (id, title) => {
    const { panes } = get()
    const pane = panes.get(id)
    if (!pane) return
    const newPanes = new Map(panes)
    newPanes.set(id, { ...pane, title })
    set({ panes: newPanes })
  },

  setTree: (tree) => set({ tree })
}))

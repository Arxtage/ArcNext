export type Direction = 'horizontal' | 'vertical'

export type SplitNode =
  | { type: 'leaf'; paneId: string }
  | { type: 'split'; direction: Direction; ratio: number; first: SplitNode; second: SplitNode }

export function leaf(paneId: string): SplitNode {
  return { type: 'leaf', paneId }
}

export function split(direction: Direction, first: SplitNode, second: SplitNode, ratio = 0.5): SplitNode {
  return { type: 'split', direction, ratio, first, second }
}

/** Split a leaf node into two, placing the new pane in the given direction */
export function splitNode(tree: SplitNode, targetId: string, direction: Direction, newPaneId: string): SplitNode {
  if (tree.type === 'leaf') {
    if (tree.paneId === targetId) {
      return split(direction, tree, leaf(newPaneId))
    }
    return tree
  }
  return {
    ...tree,
    first: splitNode(tree.first, targetId, direction, newPaneId),
    second: splitNode(tree.second, targetId, direction, newPaneId)
  }
}

/** Remove a pane from the tree, collapsing its parent split */
export function removeNode(tree: SplitNode, targetId: string): SplitNode | null {
  if (tree.type === 'leaf') {
    return tree.paneId === targetId ? null : tree
  }
  const first = removeNode(tree.first, targetId)
  const second = removeNode(tree.second, targetId)
  if (!first && !second) return null
  if (!first) return second
  if (!second) return first
  return { ...tree, first, second }
}

/** Update the ratio of a split that contains the given pane as a direct child */
export function resizeNode(tree: SplitNode, targetId: string, ratio: number): SplitNode {
  if (tree.type === 'leaf') return tree
  const clamped = Math.max(0.1, Math.min(0.9, ratio))
  const containsTarget =
    (tree.first.type === 'leaf' && tree.first.paneId === targetId) ||
    (tree.second.type === 'leaf' && tree.second.paneId === targetId)
  if (containsTarget) {
    return { ...tree, ratio: clamped }
  }
  return {
    ...tree,
    first: resizeNode(tree.first, targetId, ratio),
    second: resizeNode(tree.second, targetId, ratio)
  }
}

/** Collect all pane IDs in the tree */
export function allPaneIds(tree: SplitNode): string[] {
  if (tree.type === 'leaf') return [tree.paneId]
  return [...allPaneIds(tree.first), ...allPaneIds(tree.second)]
}

/** Find the next pane ID in traversal order, wrapping around */
export function adjacentPaneId(tree: SplitNode, currentId: string, offset: 1 | -1): string {
  const ids = allPaneIds(tree)
  const idx = ids.indexOf(currentId)
  if (idx === -1) return ids[0]
  return ids[(idx + offset + ids.length) % ids.length]
}

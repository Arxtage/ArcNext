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

export type NavDirection = 'left' | 'right' | 'up' | 'down'

function containsPane(node: SplitNode, paneId: string): boolean {
  if (node.type === 'leaf') return node.paneId === paneId
  return containsPane(node.first, paneId) || containsPane(node.second, paneId)
}

function edgeLeaf(node: SplitNode, side: 'first' | 'last'): string {
  if (node.type === 'leaf') return node.paneId
  if (side === 'first') return edgeLeaf(node.first, 'first')
  return edgeLeaf(node.second, 'last')
}

/**
 * Navigate directionally from a pane within the split tree.
 * Returns the target pane ID, or null if the pane is at the tree boundary in that direction.
 */
export function navigateDirection(tree: SplitNode, currentId: string, dir: NavDirection): string | null {
  return walk(tree, currentId, dir)
}

function walk(node: SplitNode, currentId: string, dir: NavDirection): string | null {
  if (node.type === 'leaf') return null

  const axis: Direction = (dir === 'left' || dir === 'right') ? 'horizontal' : 'vertical'
  const goingForward = dir === 'right' || dir === 'down'

  if (node.direction === axis) {
    const [from, to] = goingForward ? [node.first, node.second] : [node.second, node.first]

    if (containsPane(from, currentId)) {
      // Try to go deeper in 'from' first
      const deeper = walk(from, currentId, dir)
      if (deeper) return deeper
      // At the edge of 'from' — cross into 'to'
      return edgeLeaf(to, goingForward ? 'first' : 'last')
    }
    if (containsPane(to, currentId)) {
      return walk(to, currentId, dir)
    }
  } else {
    // Split axis doesn't match nav direction — recurse into whichever side has the pane
    if (containsPane(node.first, currentId)) return walk(node.first, currentId, dir)
    if (containsPane(node.second, currentId)) return walk(node.second, currentId, dir)
  }

  return null
}

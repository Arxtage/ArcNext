export interface PickerSelectionState {
  selectedIndex: number
  selectedKey: string | null
  hasUserNavigated: boolean
}

function clampPickerIndex(index: number, itemCount: number): number {
  if (itemCount <= 0) return 0
  return Math.max(0, Math.min(index, itemCount - 1))
}

export function createInitialPickerSelectionState(): PickerSelectionState {
  return {
    selectedIndex: 0,
    selectedKey: null,
    hasUserNavigated: false
  }
}

export function selectPickerIndex(
  state: PickerSelectionState,
  itemKeys: string[],
  index: number
): PickerSelectionState {
  const nextIndex = clampPickerIndex(index, itemKeys.length)
  const nextKey = itemKeys[nextIndex] ?? null

  if (
    state.selectedIndex === nextIndex &&
    state.selectedKey === nextKey &&
    state.hasUserNavigated
  ) {
    return state
  }

  return {
    selectedIndex: nextIndex,
    selectedKey: nextKey,
    hasUserNavigated: true
  }
}

export function movePickerSelection(
  state: PickerSelectionState,
  itemKeys: string[],
  delta: number
): PickerSelectionState {
  return selectPickerIndex(state, itemKeys, state.selectedIndex + delta)
}

export function syncPickerSelection(
  state: PickerSelectionState,
  itemKeys: string[]
): PickerSelectionState {
  if (itemKeys.length === 0) {
    if (state.selectedIndex === 0 && state.selectedKey === null) return state
    return {
      ...state,
      selectedIndex: 0,
      selectedKey: null
    }
  }

  if (!state.hasUserNavigated) {
    const topKey = itemKeys[0] ?? null
    if (state.selectedIndex === 0 && state.selectedKey === topKey) return state
    return {
      ...state,
      selectedIndex: 0,
      selectedKey: topKey
    }
  }

  if (state.selectedKey) {
    const preservedIndex = itemKeys.indexOf(state.selectedKey)
    if (preservedIndex !== -1) {
      if (preservedIndex === state.selectedIndex) return state
      return {
        ...state,
        selectedIndex: preservedIndex
      }
    }
  }

  const nextIndex = clampPickerIndex(state.selectedIndex, itemKeys.length)
  const nextKey = itemKeys[nextIndex] ?? null

  if (nextIndex === state.selectedIndex && nextKey === state.selectedKey) return state

  return {
    ...state,
    selectedIndex: nextIndex,
    selectedKey: nextKey
  }
}

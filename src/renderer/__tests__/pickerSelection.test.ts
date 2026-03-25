import { describe, expect, it } from 'vitest'
import {
  createInitialPickerSelectionState,
  movePickerSelection,
  selectPickerIndex,
  syncPickerSelection
} from '../model/pickerSelection'

describe('pickerSelection', () => {
  it('defaults to the top item until the user navigates', () => {
    const initial = createInitialPickerSelectionState()

    expect(syncPickerSelection(initial, ['top', 'next'])).toEqual({
      selectedIndex: 0,
      selectedKey: 'top',
      hasUserNavigated: false
    })

    expect(syncPickerSelection({
      selectedIndex: 2,
      selectedKey: 'third',
      hasUserNavigated: false
    }, ['top', 'next'])).toEqual({
      selectedIndex: 0,
      selectedKey: 'top',
      hasUserNavigated: false
    })
  })

  it('marks keyboard navigation as manual and tracks the selected key', () => {
    const initial = syncPickerSelection(createInitialPickerSelectionState(), ['top', 'next', 'third'])

    expect(movePickerSelection(initial, ['top', 'next', 'third'], 1)).toEqual({
      selectedIndex: 1,
      selectedKey: 'next',
      hasUserNavigated: true
    })
  })

  it('preserves the manually selected item across query result reordering', () => {
    const manuallySelected = selectPickerIndex(
      syncPickerSelection(createInitialPickerSelectionState(), ['top', 'next', 'third']),
      ['top', 'next', 'third'],
      1
    )

    expect(syncPickerSelection(manuallySelected, ['third', 'next', 'top'])).toEqual({
      selectedIndex: 1,
      selectedKey: 'next',
      hasUserNavigated: true
    })
  })

  it('falls back cleanly when the manually selected item disappears', () => {
    const manuallySelected = selectPickerIndex(
      syncPickerSelection(createInitialPickerSelectionState(), ['top', 'next', 'third']),
      ['top', 'next', 'third'],
      2
    )

    expect(syncPickerSelection(manuallySelected, ['top'])).toEqual({
      selectedIndex: 0,
      selectedKey: 'top',
      hasUserNavigated: true
    })
  })
})

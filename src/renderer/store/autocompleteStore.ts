import { create } from 'zustand'

interface DirEntry {
  path: string
  visitCount: number
  lastVisit: number
  score: number
}

interface AutocompleteState {
  active: boolean
  pending: boolean
  paneId: string | null
  query: string
  cursorPixel: { x: number; y: number }
  entries: DirEntry[]
  selectedIndex: number

  startPending: (paneId: string, cursorPixel: { x: number; y: number }) => void
  activate: (entries: DirEntry[]) => void
  deactivate: () => void
  setQuery: (q: string) => void
  appendToQuery: (char: string) => void
  setSelectedIndex: (i: number) => void
}

export const useAutocompleteStore = create<AutocompleteState>((set) => ({
  active: false,
  pending: false,
  paneId: null,
  query: '',
  cursorPixel: { x: 0, y: 0 },
  entries: [],
  selectedIndex: 0,

  startPending: (paneId, cursorPixel) =>
    set({ pending: true, active: false, paneId, cursorPixel, query: '', entries: [], selectedIndex: 0 }),

  activate: (entries) =>
    set({ pending: false, active: true, entries }),

  deactivate: () =>
    set({ active: false, pending: false, paneId: null, query: '', entries: [], selectedIndex: 0 }),

  setQuery: (q) =>
    set({ query: q, selectedIndex: 0 }),

  appendToQuery: (char) =>
    set((s) => ({ query: s.query + char, selectedIndex: 0 })),

  setSelectedIndex: (i) =>
    set({ selectedIndex: i }),
}))

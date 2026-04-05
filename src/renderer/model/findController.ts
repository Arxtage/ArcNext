import { usePaneStore } from '../store/paneStore'

interface FindHandler {
  open(): void
  close(): void
  next(): void
  prev(): void
  isOpen(): boolean
}

const handlers = new Map<string, FindHandler>()

function activeHandler(): FindHandler | undefined {
  const state = usePaneStore.getState()
  const ws = state.activeWorkspaceId
    ? state.workspaces.find((w) => w.id === state.activeWorkspaceId)
    : undefined
  if (!ws) return undefined
  return handlers.get(ws.activePaneId)
}

export const findController = {
  register:   (paneId: string, h: FindHandler) => { handlers.set(paneId, h) },
  unregister: (paneId: string) => { handlers.delete(paneId) },
  open:       () => activeHandler()?.open(),
  close:      () => activeHandler()?.close(),
  next:       () => activeHandler()?.next(),
  prev:       () => activeHandler()?.prev(),
  isOpen:     () => activeHandler()?.isOpen() ?? false,
}

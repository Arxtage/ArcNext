interface FindHandler {
  open(): void
  close(): void
  next(): void
  prev(): void
  isOpen(): boolean
}

let handler: FindHandler | null = null

export const findController = {
  register:   (h: FindHandler) => { handler = h },
  unregister: (h: FindHandler) => { if (handler === h) handler = null },
  open:       () => handler?.open(),
  close:      () => handler?.close(),
  next:       () => handler?.next(),
  prev:       () => handler?.prev(),
  isOpen:     () => handler?.isOpen() ?? false,
}

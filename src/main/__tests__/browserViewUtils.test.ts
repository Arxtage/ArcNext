import { beforeEach, describe, expect, it, vi } from 'vitest'

const setUserAgent = vi.fn()

vi.mock('electron', () => {
  class Menu {
    items: unknown[] = []

    append(item: unknown): void {
      this.items.push(item)
    }

    popup(): void {}
  }

  class MenuItem {
    constructor(options: Record<string, unknown>) {
      Object.assign(this, options)
    }
  }

  return {
    app: {
      userAgentFallback: 'Mozilla/5.0 Electron/34.0.0 ArcNext/0.6.2 Safari/537.36',
      getName: () => 'ArcNext'
    },
    session: {
      fromPartition: vi.fn(() => ({ setUserAgent }))
    },
    Menu,
    MenuItem,
    clipboard: {
      writeText: vi.fn()
    }
  }
})

import { wireBrowserViewEvents } from '../browserViewUtils'

type Listener = (...args: unknown[]) => void

function createMockView() {
  const listeners = new Map<string, Listener[]>()

  const webContents = {
    on: vi.fn((event: string, listener: Listener) => {
      const current = listeners.get(event) ?? []
      current.push(listener)
      listeners.set(event, current)
      return webContents
    }),
    removeListener: vi.fn((event: string, listener: Listener) => {
      const current = listeners.get(event) ?? []
      listeners.set(event, current.filter((entry) => entry !== listener))
      return webContents
    }),
    setWindowOpenHandler: vi.fn(),
    canGoBack: vi.fn(() => false),
    canGoForward: vi.fn(() => false),
    isAudioMuted: vi.fn(() => false),
    setVisualZoomLevelLimits: vi.fn(),
    undo: vi.fn(),
    redo: vi.fn(),
    cut: vi.fn(),
    copy: vi.fn(),
    paste: vi.fn(),
    selectAll: vi.fn(),
    goBack: vi.fn(),
    goForward: vi.fn(),
    reload: vi.fn(),
    downloadURL: vi.fn(),
    copyImageAt: vi.fn()
  }

  return {
    view: { webContents } as unknown as Electron.WebContentsView,
    emit: (event: string, ...args: unknown[]) => {
      for (const listener of listeners.get(event) ?? []) {
        listener(...args)
      }
    }
  }
}

describe('wireBrowserViewEvents', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('ignores blocked subframe load failures', () => {
    const { view, emit } = createMockView()
    const onLoadFailed = vi.fn()

    wireBrowserViewEvents(view, { onLoadFailed })

    emit(
      'did-fail-load',
      {},
      -27,
      'ERR_BLOCKED_BY_RESPONSE',
      'https://accounts.google.com/RotateCookiesPage',
      false,
      6,
      17
    )

    expect(onLoadFailed).not.toHaveBeenCalled()
  })

  it('reports main-frame load failures', () => {
    const { view, emit } = createMockView()
    const onLoadFailed = vi.fn()

    wireBrowserViewEvents(view, { onLoadFailed })

    emit(
      'did-fail-load',
      {},
      -105,
      'ERR_NAME_NOT_RESOLVED',
      'https://example.invalid',
      true,
      1,
      1
    )

    expect(onLoadFailed).toHaveBeenCalledWith(-105, 'ERR_NAME_NOT_RESOLVED')
  })

  it('still ignores cancelled main-frame loads', () => {
    const { view, emit } = createMockView()
    const onLoadFailed = vi.fn()

    wireBrowserViewEvents(view, { onLoadFailed })

    emit(
      'did-fail-load',
      {},
      -3,
      'ERR_ABORTED',
      'https://mail.google.com',
      true,
      1,
      1
    )

    expect(onLoadFailed).not.toHaveBeenCalled()
  })
})

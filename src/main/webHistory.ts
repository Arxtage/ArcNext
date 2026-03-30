import { app, ipcMain } from 'electron'
import { join } from 'path'
import { FrecencyStore } from './frecencyStore'
import { normalizeUrl, isValidUrl, isLoopbackUrl } from '../shared/urlUtils'

interface StoredWebEntry {
  url: string
  title: string
  faviconUrl: string
  visitCount: number
  lastVisit: number
}

const store = new FrecencyStore<StoredWebEntry>({
  filePath: join(app.getPath('userData'), 'web-history.json'),
  maxEntries: 500,
  keyFn: (e) => e.url
})

function sanitizeStoredFaviconUrl(faviconUrl?: string): string {
  if (!faviconUrl) return ''
  // Loopback favicons (e.g. Vite's /vite.svg) are useful while a local dev
  // server is running, but become noisy dead history once that server is gone.
  // Keep the visited URL in history, but drop the ephemeral favicon pointer.
  return isLoopbackUrl(faviconUrl) ? '' : faviconUrl
}

function recordVisit(url: string, title?: string, faviconUrl?: string): void {
  if (!isValidUrl(url)) return
  const key = normalizeUrl(url)
  const nextFaviconUrl = faviconUrl === undefined ? undefined : sanitizeStoredFaviconUrl(faviconUrl)
  const existing = store.get(key)
  if (existing) {
    existing.visitCount++
    existing.lastVisit = Date.now()
    if (title) existing.title = title
    if (nextFaviconUrl !== undefined) existing.faviconUrl = nextFaviconUrl
    store.set(key, existing)
  } else {
    store.set(key, {
      url: key,
      title: title || '',
      faviconUrl: nextFaviconUrl ?? '',
      visitCount: 1,
      lastVisit: Date.now()
    })
  }
}

export function setupWebHistory(): void {
  store.load()
  store.mapEntries((entry) => {
    const faviconUrl = sanitizeStoredFaviconUrl(entry.faviconUrl)
    return faviconUrl === entry.faviconUrl ? entry : { ...entry, faviconUrl }
  })

  ipcMain.handle('webHistory:visit', (_event, url: string, title?: string, faviconUrl?: string) => {
    recordVisit(url, title, faviconUrl)
  })

  ipcMain.handle('webHistory:query', () => {
    return store.query().map((entry) => {
      const faviconUrl = sanitizeStoredFaviconUrl(entry.faviconUrl)
      return faviconUrl === entry.faviconUrl ? entry : { ...entry, faviconUrl }
    })
  })
}

export function flushWebHistorySync(): void {
  store.flushSync()
}

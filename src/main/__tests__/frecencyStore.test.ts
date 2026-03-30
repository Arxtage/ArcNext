import { afterEach, describe, expect, it } from 'vitest'
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'fs'
import { join } from 'path'
import { tmpdir } from 'os'
import { FrecencyStore } from '../frecencyStore'

interface TestEntry {
  id: string
  value: string
  visitCount: number
  lastVisit: number
}

const tempDirs: string[] = []

function makeStore(entries: TestEntry[]) {
  const dir = mkdtempSync(join(tmpdir(), 'arcnext-frecency-'))
  tempDirs.push(dir)

  const filePath = join(dir, 'store.json')
  writeFileSync(filePath, JSON.stringify({ version: 1, entries }), 'utf-8')

  const store = new FrecencyStore<TestEntry>({
    filePath,
    maxEntries: 10,
    keyFn: (entry) => entry.id
  })

  store.load()
  return { store, filePath }
}

describe('FrecencyStore.mapEntries', () => {
  afterEach(() => {
    while (tempDirs.length > 0) {
      const dir = tempDirs.pop()
      if (dir) rmSync(dir, { recursive: true, force: true })
    }
  })

  it('updates and persists mapped entries', () => {
    const { store, filePath } = makeStore([
      { id: 'a', value: 'old', visitCount: 1, lastVisit: 1 }
    ])

    const changed = store.mapEntries((entry) =>
      entry.value === 'old' ? { ...entry, value: 'new' } : entry
    )

    expect(changed).toBe(true)

    store.flushSync()
    const data = JSON.parse(readFileSync(filePath, 'utf-8'))
    expect(data.entries[0].value).toBe('new')
  })

  it('reports no change when mapper returns the original entries', () => {
    const { store, filePath } = makeStore([
      { id: 'a', value: 'same', visitCount: 1, lastVisit: 1 }
    ])

    const before = readFileSync(filePath, 'utf-8')
    const changed = store.mapEntries((entry) => entry)

    expect(changed).toBe(false)
    store.flushSync()
    expect(readFileSync(filePath, 'utf-8')).toBe(before)
  })
})

import type { PaneInfo } from '../../shared/types'
import { cwdBasename } from './workspaceGrouping'

const FILLER_WORDS = new Set([
  'the', 'a', 'an', 'i', 'you', 'we', 'my', 'our', 'it', 'its',
  'please', 'can', 'could', 'would', 'should',
  'that', 'this', 'is', 'are', 'was', 'be', 'to', 'of',
])

export function stripAndTruncate(text: string, maxWords = 3): string {
  const words = text
    .toLowerCase()
    .replace(/["""\u201C\u201D'''\u2018\u2019`]/g, '')
    .split(/\s+/)
    .filter((w) => w && !FILLER_WORDS.has(w))
  if (words.length === 0) {
    // fallback: take raw first N words without stripping
    const raw = text.trim().split(/\s+/).slice(0, maxWords).join(' ')
    return raw.toLowerCase()
  }
  return words.slice(0, maxWords).join(' ')
}

export function paneDisplayTitle(pane: PaneInfo, grouped = false): string {
  if (pane.type === 'browser') {
    return pane.title || pane.url
  }
  const project = pane.cwd ? cwdBasename(pane.cwd) : ''

  // Agent session with user message
  if (pane.userMessage) {
    const snippet = stripAndTruncate(pane.userMessage)
    if (grouped) return snippet
    return project ? `${project} | ${snippet}` : snippet
  }

  // Active command (non-agent)
  if (pane.command) {
    const cmdSnippet = pane.command.toLowerCase().slice(0, 30).trim()
    if (grouped) return cmdSnippet
    return project ? `${project} | ${cmdSnippet}` : cmdSnippet
  }

  // Default: just project name
  return project || pane.title || 'shell'
}

export function formatTitle(title: string): string {
  if (!title || title === 'shell') return 'shell'
  const looksLikePath = title.startsWith('/') || title.includes('://')
  const parts = looksLikePath ? title.split('/') : [title]
  const name = parts[parts.length - 1] || title
  return name.length > 24 ? name.slice(0, 22) + '..' : name
}

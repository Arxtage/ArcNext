import { describe, it, expect } from 'vitest'
import { stripAndTruncate, paneDisplayTitle, formatTitle } from '../model/titleFormatter'
import type { TerminalPaneInfo, BrowserPaneInfo } from '../../shared/types'

function termPane(overrides: Partial<TerminalPaneInfo> = {}): TerminalPaneInfo {
  return { type: 'terminal', id: 'p1', title: 'shell', cwd: '/Users/me/dev/arcnext', ...overrides }
}

describe('stripAndTruncate', () => {
  it('strips filler words and keeps first 3', () => {
    expect(stripAndTruncate('fix the sidebar bug')).toBe('fix sidebar bug')
  })

  it('strips multiple filler words', () => {
    expect(stripAndTruncate('can you please fix the sidebar')).toBe('fix sidebar')
  })

  it('returns first 3 words when no filler', () => {
    expect(stripAndTruncate('refactor workspace store migration')).toBe('refactor workspace store')
  })

  it('handles custom maxWords', () => {
    expect(stripAndTruncate('refactor workspace store migration', 2)).toBe('refactor workspace')
  })

  it('lowercases output', () => {
    expect(stripAndTruncate('Fix The Sidebar Bug')).toBe('fix sidebar bug')
  })

  it('strips quotes', () => {
    expect(stripAndTruncate('"fix sidebar bug"')).toBe('fix sidebar bug')
    expect(stripAndTruncate("'add dark mode'")).toBe('add dark mode')
    expect(stripAndTruncate('\u201Cadd feature\u201D')).toBe('add feature')
  })

  it('falls back to raw words when all are filler', () => {
    expect(stripAndTruncate('the a an')).toBe('the a an')
  })

  it('handles empty string', () => {
    expect(stripAndTruncate('')).toBe('')
  })

  it('handles single meaningful word', () => {
    expect(stripAndTruncate('refactor')).toBe('refactor')
  })

  it('handles extra whitespace', () => {
    expect(stripAndTruncate('  fix   the   bug  ')).toBe('fix bug')
  })

  it('handles real-world messy prompt', () => {
    const prompt = 'can you research this feature. read code dont code yet'
    expect(stripAndTruncate(prompt)).toBe('research feature. read')
  })
})

describe('paneDisplayTitle', () => {
  describe('browser panes', () => {
    it('returns page title', () => {
      const pane: BrowserPaneInfo = {
        type: 'browser', id: 'b1', title: 'Google', url: 'https://google.com',
        canGoBack: false, canGoForward: false, isLoading: false,
      }
      expect(paneDisplayTitle(pane)).toBe('Google')
    })

    it('falls back to url when no title', () => {
      const pane: BrowserPaneInfo = {
        type: 'browser', id: 'b1', title: '', url: 'https://google.com',
        canGoBack: false, canGoForward: false, isLoading: false,
      }
      expect(paneDisplayTitle(pane)).toBe('https://google.com')
    })
  })

  describe('terminal panes — ungrouped', () => {
    it('shows project | userMessage when agent has user message', () => {
      const pane = termPane({ userMessage: 'fix the sidebar bug' })
      expect(paneDisplayTitle(pane)).toBe('arcnext | fix sidebar bug')
    })

    it('shows project | command for non-agent commands', () => {
      const pane = termPane({ command: 'npm run dev' })
      expect(paneDisplayTitle(pane)).toBe('arcnext | npm run dev')
    })

    it('shows just project name when no command or message', () => {
      const pane = termPane()
      expect(paneDisplayTitle(pane)).toBe('arcnext')
    })

    it('falls back to shell when no cwd or title', () => {
      const pane = termPane({ cwd: '', title: '' })
      expect(paneDisplayTitle(pane)).toBe('shell')
    })

    it('userMessage takes priority over command', () => {
      const pane = termPane({ command: 'claude', userMessage: 'add dark mode' })
      expect(paneDisplayTitle(pane)).toBe('arcnext | add dark mode')
    })

    it('shows snippet without project when no cwd', () => {
      const pane = termPane({ cwd: '', userMessage: 'fix bug' })
      expect(paneDisplayTitle(pane)).toBe('fix bug')
    })
  })

  describe('terminal panes — grouped', () => {
    it('omits project prefix for user message', () => {
      const pane = termPane({ userMessage: 'fix the sidebar bug' })
      expect(paneDisplayTitle(pane, true)).toBe('fix sidebar bug')
    })

    it('omits project prefix for command', () => {
      const pane = termPane({ command: 'npm run dev' })
      expect(paneDisplayTitle(pane, true)).toBe('npm run dev')
    })

    it('falls back to project name when no context', () => {
      const pane = termPane()
      expect(paneDisplayTitle(pane, true)).toBe('arcnext')
    })
  })
})

describe('formatTitle', () => {
  it('returns shell for empty or shell title', () => {
    expect(formatTitle('')).toBe('shell')
    expect(formatTitle('shell')).toBe('shell')
  })

  it('passes through short titles', () => {
    expect(formatTitle('arcnext | fix bug')).toBe('arcnext | fix bug')
  })

  it('truncates long titles at 24 chars', () => {
    const long = 'arcnext | refactor workspace store'
    expect(formatTitle(long).length).toBeLessThanOrEqual(24)
    expect(formatTitle(long)).toBe('arcnext | refactor wor..')
  })

  it('extracts basename from paths', () => {
    expect(formatTitle('/Users/me/dev/arcnext')).toBe('arcnext')
  })

  it('extracts basename from URLs', () => {
    expect(formatTitle('https://example.com/page')).toBe('page')
  })
})

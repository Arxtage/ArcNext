import { describe, it, expect, vi } from 'vitest'
import { openExternalLink } from '../model/openExternalLink'

describe('openExternalLink', () => {
  it('routes links through the app browser with opener context', () => {
    const openInNewWorkspace = vi.fn()

    openExternalLink('https://example.com', 'pane-7', openInNewWorkspace)

    expect(openInNewWorkspace).toHaveBeenCalledWith('https://example.com', 'pane-7')
  })
})

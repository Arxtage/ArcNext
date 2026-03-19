import { describe, it, expect, vi } from 'vitest'
import { openExternalLink } from '../model/openExternalLink'

describe('openExternalLink', () => {
  it('opens the final URL directly instead of a blank popup', () => {
    const openWindow = vi.fn()

    openExternalLink('https://example.com', openWindow)

    expect(openWindow).toHaveBeenCalledWith('https://example.com', '_blank', 'noopener,noreferrer')
  })
})

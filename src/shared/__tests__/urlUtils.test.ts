import { describe, expect, it } from 'vitest'
import { isLoopbackUrl } from '../urlUtils'

describe('isLoopbackUrl', () => {
  it('detects common local development hosts', () => {
    expect(isLoopbackUrl('http://localhost:8000/vite.svg')).toBe(true)
    expect(isLoopbackUrl('http://127.0.0.1:3000/favicon.ico')).toBe(true)
    expect(isLoopbackUrl('http://0.0.0.0:5173')).toBe(true)
    expect(isLoopbackUrl('http://[::1]:8080')).toBe(true)
    expect(isLoopbackUrl('http://app.localhost:3000')).toBe(true)
  })

  it('does not treat normal sites as loopback', () => {
    expect(isLoopbackUrl('https://mail.google.com')).toBe(false)
    expect(isLoopbackUrl('https://example.com/favicon.ico')).toBe(false)
    expect(isLoopbackUrl('not-a-url')).toBe(false)
  })
})

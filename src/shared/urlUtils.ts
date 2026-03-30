/** Normalize a URL for deduplication/comparison: lowercase hostname, strip trailing slash. */
export function normalizeUrl(url: string): string {
  try {
    const u = new URL(url)
    u.hostname = u.hostname.toLowerCase()
    let normalized = u.toString()
    if (normalized.endsWith('/')) normalized = normalized.slice(0, -1)
    return normalized
  } catch {
    return url.replace(/\/$/, '').toLowerCase()
  }
}

export function isValidUrl(url: string): boolean {
  return /^https?:\/\//i.test(url)
}

export function isLoopbackUrl(url: string): boolean {
  try {
    const hostname = new URL(url).hostname.toLowerCase()
    return (
      hostname === 'localhost' ||
      hostname.endsWith('.localhost') ||
      hostname === '0.0.0.0' ||
      hostname === '::1' ||
      /^\[::1\]$/.test(hostname) ||
      /^127(?:\.\d{1,3}){3}$/.test(hostname)
    )
  } catch {
    return false
  }
}

export function ensureProtocol(input: string): string {
  if (/^https?:\/\//i.test(input)) return input
  return `https://${input}`
}

export function hostnameFromUrl(url: string): string {
  try {
    return new URL(url).hostname
  } catch {
    return url
  }
}

/** Strip protocol and www, returning host + path + search. */
export function bareUrl(url: string): string {
  try {
    const u = new URL(url)
    const host = u.hostname.replace(/^www\./, '')
    const path = u.pathname === '/' ? '' : u.pathname
    return host + path + u.search
  } catch {
    return url.replace(/^https?:\/\/(www\.)?/i, '')
  }
}

export function compactUrl(url: string): string {
  const bare = bareUrl(url)
  if (bare.length > 40) return bare.slice(0, 37) + '...'
  return bare
}

export function looksLikeUrl(input: string): boolean {
  if (/^https?:\/\//i.test(input)) return true
  return input.includes('.') && !input.includes(' ') && input.length > 3
}

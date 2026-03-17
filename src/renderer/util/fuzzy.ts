import type { ReactNode } from 'react'
import { createElement } from 'react'

export function fuzzyMatch(text: string, query: string): boolean {
  const lower = text.toLowerCase()
  const q = query.toLowerCase()
  let j = 0
  for (let i = 0; i < lower.length && j < q.length; i++) {
    if (lower[i] === q[j]) j++
  }
  return j === q.length
}

export function highlightMatch(text: string, query: string): ReactNode {
  if (!query) return text
  const lower = text.toLowerCase()
  const q = query.toLowerCase()
  const parts: ReactNode[] = []
  let j = 0
  let plain = ''
  for (let i = 0; i < text.length; i++) {
    if (j < q.length && lower[i] === q[j]) {
      if (plain) { parts.push(plain); plain = '' }
      parts.push(createElement('mark', { key: i }, text[i]))
      j++
    } else {
      plain += text[i]
    }
  }
  if (plain) parts.push(plain)
  return parts
}

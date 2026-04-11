type OpenInNewWorkspaceFn = (url: string, sourcePaneId?: string) => void

/**
 * Open terminal links as first-class browser workspaces instead of routing
 * through window.open, so we can preserve opener context for Back behavior.
 */
export function openExternalLink(
  url: string,
  sourcePaneId: string,
  openInNewWorkspace: OpenInNewWorkspaceFn = window.arcnext.browser.openInNewWorkspace
): void {
  openInNewWorkspace(url, sourcePaneId)
}

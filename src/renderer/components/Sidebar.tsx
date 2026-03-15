import { useState } from 'react'
import { usePaneStore, Workspace, PaneInfo } from '../store/paneStore'
import { allPaneIds } from '../model/splitTree'

export default function Sidebar() {
  const workspaces = usePaneStore((s) => s.workspaces)
  const activeWorkspaceId = usePaneStore((s) => s.activeWorkspaceId)
  const panes = usePaneStore((s) => s.panes)
  const switchWorkspace = usePaneStore((s) => s.switchWorkspace)
  const addWorkspace = usePaneStore((s) => s.addWorkspace)
  const removeWorkspace = usePaneStore((s) => s.removeWorkspace)
  const mergeWorkspaces = usePaneStore((s) => s.mergeWorkspaces)

  const [dragSourceId, setDragSourceId] = useState<string | null>(null)
  const [dragOverId, setDragOverId] = useState<string | null>(null)

  return (
    <div className="sidebar">
      <div className="sidebar-header" />
      <div className="sidebar-list">
        {workspaces.map((ws) => (
          <WorkspaceRow
            key={ws.id}
            workspace={ws}
            panes={panes}
            isActive={ws.id === activeWorkspaceId}
            isDragging={ws.id === dragSourceId}
            isDropTarget={ws.id === dragOverId && ws.id !== dragSourceId}
            onSelect={() => switchWorkspace(ws.id)}
            onClose={() => removeWorkspace(ws.id)}
            onDragStart={() => setDragSourceId(ws.id)}
            onDragOver={(e) => {
              e.preventDefault()
              setDragOverId(ws.id)
            }}
            onDragLeave={(e) => {
              if (!(e.currentTarget as HTMLElement).contains(e.relatedTarget as Node)) {
                setDragOverId(null)
              }
            }}
            onDrop={(e) => {
              e.preventDefault()
              if (dragSourceId && dragSourceId !== ws.id) {
                const direction = e.shiftKey ? 'horizontal' : 'vertical'
                mergeWorkspaces(ws.id, dragSourceId, direction)
              }
              setDragSourceId(null)
              setDragOverId(null)
            }}
            onDragEnd={() => {
              setDragSourceId(null)
              setDragOverId(null)
            }}
          />
        ))}
      </div>
      <div className="sidebar-footer">
        <button className="sidebar-add" onClick={addWorkspace}>
          + New Workspace
        </button>
      </div>
    </div>
  )
}

interface WorkspaceRowProps {
  workspace: Workspace
  panes: Map<string, PaneInfo>
  isActive: boolean
  isDragging: boolean
  isDropTarget: boolean
  onSelect: () => void
  onClose: () => void
  onDragStart: () => void
  onDragOver: (e: React.DragEvent) => void
  onDragLeave: (e: React.DragEvent) => void
  onDrop: (e: React.DragEvent) => void
  onDragEnd: () => void
}

function WorkspaceRow({
  workspace, panes, isActive, isDragging, isDropTarget,
  onSelect, onClose, onDragStart, onDragOver, onDragLeave, onDrop, onDragEnd
}: WorkspaceRowProps) {
  const paneIds = allPaneIds(workspace.tree)
  const paneInfos = paneIds.map((id) => panes.get(id)).filter(Boolean) as PaneInfo[]
  const isSinglePane = paneInfos.length === 1

  const className = [
    'ws-row',
    isActive && 'active',
    isDragging && 'ws-dragging',
    isDropTarget && 'ws-drop-target'
  ].filter(Boolean).join(' ')

  return (
    <div
      className={className}
      onClick={onSelect}
      draggable
      onDragStart={(e) => {
        e.dataTransfer.effectAllowed = 'move'
        onDragStart()
      }}
      onDragOver={onDragOver}
      onDragLeave={onDragLeave}
      onDrop={onDrop}
      onDragEnd={onDragEnd}
    >
      {isSinglePane ? (
        <div className="ws-single">
          <span className="ws-icon">&#9632;</span>
          <span className="ws-title">{formatTitle(paneInfos[0].title)}</span>
        </div>
      ) : (
        <div className="ws-multi">
          {paneInfos.map((p) => (
            <span key={p.id} className={`ws-pill ${p.id === workspace.activePaneId ? 'pill-active' : ''}`}>
              {formatTitle(p.title)}
            </span>
          ))}
        </div>
      )}
      <button
        className="ws-close"
        draggable={false}
        onClick={(e) => { e.stopPropagation(); onClose() }}
      >
        &times;
      </button>
    </div>
  )
}

function formatTitle(title: string): string {
  if (!title || title === 'shell') return 'shell'
  // Truncate long titles, show last path segment if it looks like a path
  const parts = title.split('/')
  const name = parts[parts.length - 1] || title
  return name.length > 18 ? name.slice(0, 16) + '...' : name
}

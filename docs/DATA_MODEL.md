# Data Model

## Entity Relationships

```
Workspace (1:1 with window)
├── tabGroups: [TabGroup]         # Tidy groups
├── ungroupedTabs: [Tab]          # Loose tabs
├── activeTabID: UUID?
└── splitConfiguration: SplitNode?

TabGroup
├── id: UUID
├── name: String
├── color: GroupColor
├── isCollapsed: Bool
└── tabs: [Tab]

Tab
├── id: UUID
├── content: any TabContent       # Terminal, future browser, dashboard
├── title: String
├── isPinned: Bool
├── groupID: UUID?
├── createdAt: Date
└── lastAccessedAt: Date

Pane
├── id: UUID
├── tabStack: [Tab]               # Stack of tabs in this pane
└── activeTabIndex: Int

SplitNode (indirect enum, binary tree)
├── .leaf(paneID: UUID)           # References a Pane
└── .split(direction, ratio, first, second)

TerminalSession (conforms to TabContent)
├── id: UUID
├── terminal: Terminal (SwiftTerm)
├── ptyHandle: PTYHandle
├── currentDirectory: URL?
├── shellPID: pid_t
├── state: SessionState
└── profile: TerminalProfile

TerminalProfile
├── fontFamily: String
├── fontSize: CGFloat
├── colorScheme: ColorScheme
├── cursorStyle: CursorStyle
└── scrollbackLines: Int
```

## Key Design Decisions

### Panes own tab stacks
Each `Pane` contains a `[Tab]` stack, not a single tab reference. This prevents complexity when combining splits with drag/reparent/restore operations.

### SplitNode references Panes, not Tabs
`SplitNode.leaf(paneID)` references a `Pane`, which owns its tab stack. This cleanly separates layout (splits) from content management (tabs).

### TabContent protocol
All tab content types conform to `TabContent`. This is the extensibility point for P2 (browser) and P3 (dashboard).

### Workspace is 1:1 with window
Each window gets its own `Workspace`. Multi-window support means multiple `Workspace` instances.

## Persistence

### Session Restore (P1)
- `Workspace` conforms to `Codable`
- Saved to `~/Library/Application Support/ArcNext/workspace.json` on quit
- Restored on launch
- Terminal scroll buffer NOT persisted (too large); only metadata restored
- PTY reconnection not possible in P1 (single process)

### Session Survival (P2)
- PTY server persists sessions across app crashes
- Full terminal state recoverable via server reconnection

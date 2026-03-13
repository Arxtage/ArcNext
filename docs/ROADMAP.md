# Roadmap

## P1 — Core Terminal (implement now)

- [ ] Vertical sidebar tabs (SwiftUI)
- [ ] Split panes with tab stacks
- [ ] Manual Tidy (named/colored tab groups)
- [ ] Universal Cmd+T palette
- [ ] Session restore (save/restore on quit/launch)
- [ ] Theming (dark mode, colors, fonts)
- [ ] Core Text terminal rendering via SwiftTerm

## P2 — Enhanced (design for, defer)

- [ ] Embedded browser via WKWebView
- [ ] Metal terminal renderer (120fps ProMotion, glyph atlas)
- [ ] Multi-server PTY model (sessions survive crashes)
- [ ] Auto-Tidy (smart grouping by project/theme)

## P3 — Agent Platform (design for, defer)

- [ ] Agent Command Center dashboard (running agents, status, resource usage)
- [ ] Agent orchestration (start/stop/restart from UI)

## Implementation Order (P1)

### Step 1: Docs & project config
- README, architecture docs, Package.swift, config files

### Step 2: Core model layer
- All models in `ArcNextCore/Models/`
- All protocols in `ArcNextCore/Protocols/`
- Unit tests for SplitNode, TabManager, TidyService

### Step 3: Services
- PTYService, SessionManager, TabManager, TidyService, DirectoryTracker

### Step 4: UI layer
- MainWindowController + MainWindow
- SidebarView (SwiftUI)
- TerminalContainerView (AppKit)
- SplitContainerView + SplitController
- PaletteView (Cmd+T)

### Step 5: Integration & polish
- Wire sidebar <-> tab management <-> terminal views
- Session restore, theming, keyboard shortcuts

## Verification Criteria

1. `swift build` succeeds with no warnings
2. `swift test` passes all core model tests
3. App launches, shows sidebar with one terminal tab
4. Can create new tabs via Cmd+T
5. Can split tabs vertically
6. Can group tabs via Tidy
7. Session state persists across app restart

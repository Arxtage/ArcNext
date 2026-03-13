# Architecture

## Overview

ArcNext is a native macOS terminal emulator that combines Arc browser's sidebar-driven UX with a terminal-first workflow. It targets developers running AI agents and terminal-heavy toolchains who rarely need a browser.

## Module Structure

### ArcNextApp
Entry point. Owns `AppState`, the `@main` struct, and resource bundles. Wires together Core and UI.

### ArcNextCore
Pure logic layer with zero UI dependencies. Contains:
- **Models** — `Workspace`, `Tab`, `TabGroup`, `Pane`, `SplitNode`, `TerminalSession`, `TerminalProfile`
- **Protocols** — `TabContent`, `Restorable`, `Themeable`, `PTYProviding`
- **Services** — `SessionManager`, `PTYService`, `TabManager`, `TidyService`, `DirectoryTracker`

### ArcNextUI
All UI code. AppKit for performance-critical views (terminal viewport, split management), SwiftUI for sidebar and palette.
- **Sidebar/** — SwiftUI vertical tab list with drag/drop, group collapsing
- **Terminal/** — AppKit `TerminalContainerView` wrapping SwiftTerm's `TerminalView`
- **Split/** — `SplitContainerView` mapping `SplitNode` tree to `NSSplitView` hierarchy
- **Palette/** — Universal Cmd+T palette (SwiftUI overlay)
- **Window/** — `MainWindowController` + `MainWindow` (NSWindowController/NSWindow subclasses)

### ArcNextBrowser (P2 stub)
Placeholder module for future WKWebView-based browser tabs.

## Key Patterns

### AppKit + SwiftUI Hybrid
- `MainWindowController` manages the NSWindow lifecycle
- `NSHostingView` embeds SwiftUI sidebar into the AppKit window
- Terminal views remain pure AppKit for input handling fidelity
- `NSViewRepresentable` bridges AppKit terminal views into SwiftUI when needed

### Observable State
- `AppState` is `@Observable` (Observation framework, macOS 15+)
- Single source of truth: `AppState` owns the `Workspace` model
- UI observes state changes automatically via `@Observable`
- No Combine, no `ObservableObject` — pure Observation framework

### SplitNode Binary Tree
`SplitNode` is an indirect enum forming a binary tree:
- `.leaf(paneID)` — terminal pane
- `.split(direction, ratio, first, second)` — recursive split

The UI layer walks this tree to build nested `NSSplitView` hierarchies.

### Tab Content Protocol
`TabContent` is the extensibility point. Terminal, browser (P2), and dashboard (P3) all conform. This decouples tab management from content type.

## Process Model

### P1: Single Process
- App process owns all PTY file descriptors
- `forkpty()` creates child shells
- Session state saved to disk on quit, restored on launch
- Crash = lose all sessions

### P2: Server Model (deferred)
- Separate PTY server process survives app crashes
- App connects to server via Unix domain socket
- Sessions persist across app restarts

## Security

- PTY via POSIX `forkpty()`, no privilege escalation
- Commands as `[String]` argv arrays, never string interpolation
- Explicit env var allowlist for child processes
- Developer ID + notarization (not Mac App Store)
- Swift 6 strict concurrency for data-race safety

## Distribution

Developer ID signed + notarized. Terminal apps require `fork()/exec()` which is incompatible with Mac App Store sandboxing.

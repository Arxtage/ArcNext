# Design Decisions

## Swift 6 + AppKit/SwiftUI Hybrid

**Decision:** Use Swift 6 with AppKit for terminal views and SwiftUI for sidebar/palette.

**Why:** Apple explicitly supports `NSHostingView`/`NSViewRepresentable` bridging. SwiftUI is natural for list-based sidebar UI and overlay palette. AppKit is required for terminal input handling (key events, IME, mouse reporting) and `NSSplitView` performance. Swift 6 strict concurrency catches data-race bugs at compile time.

**Alternative considered:** Pure SwiftUI — rejected because terminal views need precise control over key events, focus, and rendering that SwiftUI's event model doesn't expose.

## SwiftTerm over building from scratch

**Decision:** Use SwiftTerm (MIT) as the terminal emulation library.

**Why:** Terminal emulation is a multi-year effort (VT100, xterm, Unicode width, bracketed paste, mouse reporting, alt screen, etc.). SwiftTerm is mature, MIT-licensed, Swift-native, and used in commercial apps.

**Risk:** Dependency on external maintenance. Mitigated by SwiftTerm being actively maintained and MIT-licensed (can fork if needed).

## Panes own tab stacks

**Decision:** Each `Pane` holds a `[Tab]` stack. `SplitNode.leaf` references a `Pane`, not a `Tab`.

**Why:** If splits reference tabs directly, drag/reparent/restore becomes complex — you need a separate mapping layer. Pane-owns-stack makes splits and tab management orthogonal.

**Source:** Codex peer review round 1.

## WKWebView over CEF/Chromium (P2)

**Decision:** Use WKWebView for future embedded browser, not CEF.

**Why:** WKWebView already has multi-process sandboxed architecture and is built into macOS. CEF brings heavy build/update/sandbox overhead for what is a "rare browser" feature in a terminal-first app.

**Trade-off:** WKWebView has more limited extension/DevTools support than CEF. Acceptable for our use case (occasional web viewing, not a primary browser).

## Manual Tidy before Auto-Tidy

**Decision:** P1 implements manual named/colored tab groups only. Auto-tidy deferred to P2.

**Why:** Manual grouping is deterministic and immediately useful. Auto-tidy requires heuristics (project detection, theme analysis) that need iteration to get right.

## Core Text rendering (P1), Metal (P2)

**Decision:** Ship with SwiftTerm's default Core Text renderer. Metal deferred to P2.

**Why:** Core Text is sufficient for initial launch. Metal only matters at high refresh rates (120fps ProMotion) or with very large scrollback. Premature optimization risk.

## Single process (P1), server model (P2)

**Decision:** Single process with save-on-quit session restore for P1. PTY server process for crash survival deferred to P2.

**Why:** Single process is simpler to build, debug, and ship. Session restore (save workspace JSON on quit) covers the common case. Server model only needed for crash survival, which is a P2 concern.

## Cmd+T = Universal Palette

**Decision:** Cmd+T opens a universal palette (like Spotlight/Raycast), not just a folder picker.

**Why:** A folder picker is too narrow. The palette should open recent folders, switch tabs, reopen closed tabs, jump to groups, and run actions. This matches Arc's Cmd+T and modern app launcher UX.

**Source:** Codex peer review round 1.

## Observation framework over Combine

**Decision:** Use `@Observable` (Observation framework) for all state management. No `ObservableObject`, no Combine.

**Why:** macOS 15 minimum means Observation framework is available. It's simpler, more performant (fine-grained tracking), and the future direction of SwiftUI state management. No reason to use the older pattern.

## iTerm2 reference, no code

**Decision:** Reference iTerm2 for architecture study only. No code lifting.

**Why:** iTerm2 is GPL-licensed. Studying its PseudoTerminal/PTYTab/PTYSession hierarchy and NSSplitView approach is valuable for design. All implementation is original.

# ArcNext

A native macOS terminal emulator with Arc browser-style UX. Built for developers who've shifted from browser+terminal+IDE to terminal-heavy workflows.

## Features

- **Vertical sidebar tabs** — Arc-style SwiftUI list of open terminal sessions
- **Split panes** — Each pane owns a tab stack for flexible layouts
- **Tidy (tab groups)** — Manual named/colored groups, collapsible in sidebar
- **Universal Cmd+T palette** — Open folders, switch tabs, reopen closed tabs, jump to groups, run actions
- **Session restore** — Save/restore workspace on quit/launch
- **Theming** — Dark mode, configurable colors/fonts

## Requirements

- macOS 15+
- Swift 6.0+
- Xcode 16+

## Build

```bash
swift build
```

## Run

```bash
swift run ArcNext
```

## Test

```bash
swift test
```

## Tech Stack

| Component | Choice |
|-----------|--------|
| Language | Swift 6 |
| UI | AppKit + SwiftUI hybrid |
| Terminal | SwiftTerm (SPM) |
| Rendering | Core Text (P1), Metal (P2) |
| Min target | macOS 15 |

## Project Structure

```
Sources/
├── ArcNextApp/       # Entry point, AppState
├── ArcNextCore/      # Models, Services, Protocols (no UI)
├── ArcNextUI/        # Sidebar, Terminal, Split, Palette, Window
└── ArcNextBrowser/   # P2 stub module
Tests/
└── ArcNextCoreTests/ # Unit tests for core logic
```

## Architecture

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for details.

## License

Proprietary. All rights reserved.

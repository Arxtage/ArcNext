# ArcNext

You like Arc Browser? You like living in the terminal with AI agents? You'll love ArcNext.

A native macOS terminal emulator with Arc browser-style UX. Built for developers who've shifted from browser+terminal+IDE to terminal-heavy workflows.

## Why build this?

The times are changing, i spend more time in terminal than in browser. I run a dozen of agents with different context and need to jump between them. See this https://x.com/armantsaturian/status/2032392669763158205?s=20 and https://x.com/karpathy/status/2031767720933634100. We need a new surface. Arc + Terminal with proper Agent Command Control = ArcTerm.

- **Vertical sidebar tabs** — Arc-style SwiftUI list of open terminal sessions
- **Split panes** — Each pane owns a tab stack for flexible layouts
- **Combined split tabs** — Visible split panes collapse into one compact sidebar row
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

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+T` | Toggle palette |
| `Cmd+D` | Split vertical |
| `Cmd+Shift+D` | Split horizontal |
| `Cmd+W` | Close active tab |
| `Cmd+1-9` | Switch to tab by index |
| `Cmd+[` / `Cmd+]` | Cycle tabs |

## License

MIT License. See [LICENSE](LICENSE) for details.

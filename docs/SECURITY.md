# Security Architecture

## PTY Management

- Standard POSIX `forkpty()` — no privilege escalation
- File descriptors wrapped in RAII `PTYHandle` struct (auto-close on deinit)
- No raw FD leaks across service boundaries

## Command Execution

- Commands passed as `[String]` argv arrays via `posix_spawn`/`exec`
- **Never** shell string interpolation — eliminates injection attacks
- No `system()`, no `popen()`, no shell-evaluated strings

## Environment Variables

- Explicit allowlist for child process environment
- Only propagate known-safe variables (`PATH`, `HOME`, `TERM`, `LANG`, etc.)
- Strip sensitive parent process env vars before fork

## Concurrency Safety

- Swift 6 strict concurrency mode (`StrictConcurrency` upcoming feature)
- `Sendable` enforcement across all actor/task boundaries
- Compile-time data-race elimination

## Distribution

- **Developer ID + notarization** (not Mac App Store)
- Terminal apps require `fork()`/`exec()` which is incompatible with App Sandbox
- Hardened runtime enabled
- No entitlements beyond standard terminal needs

## Future: Browser (P2)

- WKWebView runs in Apple's own multi-process sandboxed architecture
- Each web content process is sandboxed independently
- No direct access to PTY file descriptors from web content

## Threat Model

| Threat | Mitigation |
|--------|------------|
| Command injection | argv arrays, no shell interpolation |
| FD leaks | RAII PTYHandle |
| Data races | Swift 6 strict concurrency |
| Env var leakage | Explicit allowlist |
| Malicious web content (P2) | WKWebView process sandbox |
| Unsigned binary | Developer ID + notarization |

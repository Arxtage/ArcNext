import AppKit
import ArcNextCore
import SwiftTerm

/// AppKit container that hosts a SwiftTerm LocalProcessTerminalView for a given session.
/// LocalProcessTerminalView handles PTY spawning, key input, resize, and SIGCHLD automatically.
public final class TerminalContainerView: NSView, @preconcurrency LocalProcessTerminalViewDelegate {
    private var terminalView: LocalProcessTerminalView?
    nonisolated(unsafe) private var mouseMonitor: Any?
    private let paneID: UUID
    private let session: TerminalSession
    private let appState: AppState

    public init(paneID: UUID, session: TerminalSession, appState: AppState) {
        self.paneID = paneID
        self.session = session
        self.appState = appState
        super.init(frame: .zero)
        setupTerminal()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let mouseMonitor {
            NSEvent.removeMonitor(mouseMonitor)
        }
    }

    private func setupTerminal() {
        let terminal = LocalProcessTerminalView(frame: bounds)
        terminal.processDelegate = self
        terminal.autoresizingMask = [.width, .height]
        terminal.translatesAutoresizingMaskIntoConstraints = true

        // Apply theme
        session.profile.theme.apply(to: terminal)

        addSubview(terminal)
        terminalView = terminal

        // Wire up cleanup closure
        session.onTerminate = { [weak terminal] in
            terminal?.terminate()
        }

        // Start the shell process
        let shell = appState.sessionManager.defaultShell()
        let cwd = session.currentDirectory?.path
        terminal.startProcess(executable: shell, args: ["-l"], currentDirectory: cwd)
        session.state = .running
    }

    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        if window != nil, mouseMonitor == nil {
            setupMouseMonitor()
        }

        guard window != nil, appState.workspace.activePaneID == paneID else { return }
        DispatchQueue.main.async { [weak self] in
            self?.focusTerminal()
        }
    }

    public func focusTerminal() {
        _ = activatePaneAndFocusTerminal()
    }

    @discardableResult
    private func activatePaneAndFocusTerminal() -> Bool {
        if appState.workspace.activePaneID != paneID {
            appState.workspace.activePaneID = paneID
        }

        guard let terminalView else { return false }
        return window?.makeFirstResponder(terminalView) ?? false
    }

    private func setupMouseMonitor() {
        mouseMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] event in
            guard let self,
                  let window = self.window,
                  event.window === window,
                  let terminalView = self.terminalView else {
                return event
            }

            let pointInTerminal = terminalView.convert(event.locationInWindow, from: nil)
            guard terminalView.bounds.contains(pointInTerminal) else {
                return event
            }

            self.focusTerminal()
            return event
        }
    }

    // MARK: - LocalProcessTerminalViewDelegate

    public func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

    public func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        for tab in appState.workspace.tabs.values {
            if tab.contentID == session.id {
                tab.title = title
                break
            }
        }
    }

    public func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        guard let directory, let url = URL(string: directory) ?? URL(fileURLWithPath: directory) as URL? else { return }
        session.currentDirectory = url
        appState.directoryTracker.recordDirectory(url)
    }

    public func processTerminated(source: TerminalView, exitCode: Int32?) {
        session.state = .stopped
        TerminalViewRepresentable.removeFromCache(sessionID: session.id)
    }

    public func terminate() {
        terminalView?.terminate()
    }

    public override func layout() {
        super.layout()
        terminalView?.frame = bounds
    }
}

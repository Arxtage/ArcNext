import AppKit
import ArcNextCore
import SwiftTerm

/// AppKit container that hosts a SwiftTerm LocalProcessTerminalView for a given session.
/// LocalProcessTerminalView handles PTY spawning, key input, resize, and SIGCHLD automatically.
public final class TerminalContainerView: NSView, @preconcurrency LocalProcessTerminalViewDelegate {
    private var terminalView: LocalProcessTerminalView?
    private let session: TerminalSession
    private let appState: AppState

    public init(session: TerminalSession, appState: AppState) {
        self.session = session
        self.appState = appState
        super.init(frame: .zero)
        setupTerminal()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    }

    public func terminate() {
        terminalView?.terminate()
    }

    public override func layout() {
        super.layout()
        terminalView?.frame = bounds
    }
}

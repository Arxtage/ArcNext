import Foundation

/// Manages terminal session lifecycle: creation, tracking, and cleanup.
/// PTY spawning is now handled by LocalProcessTerminalView in the UI layer.
@Observable
public final class SessionManager {
    public var sessions: [UUID: TerminalSession] = [:]
    private let ptyService: PTYService

    public init(ptyService: PTYService = PTYService()) {
        self.ptyService = ptyService
    }

    @discardableResult
    public func createSession(
        workingDirectory: URL? = nil,
        profile: TerminalProfile = .default
    ) -> TerminalSession {
        let session = TerminalSession(
            currentDirectory: workingDirectory,
            state: .running,
            profile: profile
        )
        sessions[session.id] = session
        return session
    }

    public func closeSession(_ sessionID: UUID) {
        guard let session = sessions[sessionID] else { return }
        session.onTerminate?()
        session.state = .stopped
        sessions.removeValue(forKey: sessionID)
    }

    public func closeAll() {
        for id in sessions.keys {
            closeSession(id)
        }
    }

    public func defaultShell() -> String {
        ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
    }
}

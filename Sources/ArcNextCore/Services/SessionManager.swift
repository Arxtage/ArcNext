import Foundation

/// Manages terminal session lifecycle: creation, tracking, and cleanup.
@Observable
public final class SessionManager {
    public private(set) var sessions: [UUID: TerminalSession] = [:]
    private let ptyService: PTYService

    public init(ptyService: PTYService = PTYService()) {
        self.ptyService = ptyService
    }

    @discardableResult
    public func createSession(
        shell: String? = nil,
        workingDirectory: URL? = nil,
        profile: TerminalProfile = .default
    ) throws -> TerminalSession {
        let resolvedShell = shell ?? defaultShell()
        let session = TerminalSession(
            currentDirectory: workingDirectory,
            profile: profile
        )

        let env = ProcessInfo.processInfo.environment
        let handle = try ptyService.spawn(
            shell: resolvedShell,
            arguments: ["-l"],
            environment: env,
            workingDirectory: workingDirectory
        )

        session.ptyHandle = handle
        session.shellPID = handle.pid
        session.state = .running

        sessions[session.id] = session
        return session
    }

    public func closeSession(_ sessionID: UUID) {
        guard let session = sessions[sessionID] else { return }
        if let handle = session.ptyHandle {
            ptyService.terminate(handle: handle)
        }
        session.state = .stopped
        sessions.removeValue(forKey: sessionID)
    }

    public func closeAll() {
        for id in sessions.keys {
            closeSession(id)
        }
    }

    public func resizeSession(_ sessionID: UUID, cols: UInt16, rows: UInt16) {
        guard let session = sessions[sessionID],
              let handle = session.ptyHandle else { return }
        try? ptyService.resize(handle: handle, cols: cols, rows: rows)
    }

    private func defaultShell() -> String {
        ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
    }
}

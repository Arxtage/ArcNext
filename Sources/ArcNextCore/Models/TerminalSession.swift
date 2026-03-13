import Foundation

public enum SessionState: String, Codable, Sendable {
    case running
    case stopped
    case failed
}

@Observable
public final class TerminalSession: Identifiable {
    public let id: UUID
    public var currentDirectory: URL?
    public var shellPID: pid_t
    public var state: SessionState
    public var profile: TerminalProfile
    public var ptyHandle: PTYHandle?

    public init(
        id: UUID = UUID(),
        currentDirectory: URL? = nil,
        shellPID: pid_t = 0,
        state: SessionState = .running,
        profile: TerminalProfile = .default
    ) {
        self.id = id
        self.currentDirectory = currentDirectory
        self.shellPID = shellPID
        self.state = state
        self.profile = profile
    }

    public var title: String {
        if let dir = currentDirectory?.lastPathComponent {
            return dir
        }
        return "Terminal"
    }
}

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
    public var state: SessionState
    public var profile: TerminalProfile
    public var onTerminate: (() -> Void)?

    public init(
        id: UUID = UUID(),
        currentDirectory: URL? = nil,
        state: SessionState = .running,
        profile: TerminalProfile = .default
    ) {
        self.id = id
        self.currentDirectory = currentDirectory
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

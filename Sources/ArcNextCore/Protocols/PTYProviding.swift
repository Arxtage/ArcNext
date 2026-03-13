import Foundation

/// Abstraction over PTY creation and management.
/// Allows mocking in tests and swapping to a server model in P2.
public protocol PTYProviding: Sendable {
    func spawn(
        shell: String,
        arguments: [String],
        environment: [String: String],
        workingDirectory: URL?
    ) throws -> PTYHandle

    func resize(handle: PTYHandle, cols: UInt16, rows: UInt16) throws
    func terminate(handle: PTYHandle)
}

/// RAII wrapper around a PTY file descriptor pair.
/// Automatically closes FDs on deinit to prevent leaks.
public final class PTYHandle: Sendable {
    public let masterFD: Int32
    public let slaveFD: Int32
    public let pid: pid_t

    public init(masterFD: Int32, slaveFD: Int32, pid: pid_t) {
        self.masterFD = masterFD
        self.slaveFD = slaveFD
        self.pid = pid
    }

    deinit {
        close(masterFD)
        close(slaveFD)
    }
}

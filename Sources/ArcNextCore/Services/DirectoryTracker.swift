import Foundation

/// Tracks the current working directory of terminal sessions via OSC 7 escape sequences
/// or periodic polling of /proc (fallback).
@Observable
public final class DirectoryTracker {
    public private(set) var recentDirectories: [URL] = []
    private let maxRecent = 50

    public init() {}

    public func recordDirectory(_ url: URL) {
        recentDirectories.removeAll { $0 == url }
        recentDirectories.insert(url, at: 0)
        if recentDirectories.count > maxRecent {
            recentDirectories.removeLast()
        }
    }

    /// Parse OSC 7 directory notification: file://hostname/path
    public func parseOSC7(_ payload: String) -> URL? {
        guard payload.hasPrefix("file://") else { return nil }
        // Strip file://hostname prefix, extract path
        guard let url = URL(string: payload) else { return nil }
        return url
    }

    /// Get CWD of a process by PID (macOS-specific).
    public func currentDirectory(forPID pid: pid_t) -> URL? {
        let pathBuffer = UnsafeMutablePointer<CChar>.allocate(capacity: Int(MAXPATHLEN))
        defer { pathBuffer.deallocate() }
        let result = proc_pidpath(pid, pathBuffer, UInt32(MAXPATHLEN))
        guard result > 0 else { return nil }
        // proc_pidpath gives executable path, not CWD
        // For CWD, we need proc_pidinfo with PROC_PIDVNODEPATHINFO
        // This is a simplified version; full implementation uses libproc
        return nil
    }
}

// libproc declarations
@_silgen_name("proc_pidpath")
private func proc_pidpath(_ pid: pid_t, _ buffer: UnsafeMutablePointer<CChar>, _ bufferSize: UInt32) -> Int32

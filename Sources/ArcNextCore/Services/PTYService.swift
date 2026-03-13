import Foundation

/// Default PTY provider using POSIX forkpty().
public final class PTYService: PTYProviding, @unchecked Sendable {
    private let allowedEnvVars: Set<String> = [
        "PATH", "HOME", "USER", "SHELL", "TERM", "LANG",
        "LC_ALL", "LC_CTYPE", "TMPDIR", "XDG_RUNTIME_DIR",
        "COLORTERM", "TERM_PROGRAM",
    ]

    public init() {}

    public func spawn(
        shell: String,
        arguments: [String],
        environment: [String: String],
        workingDirectory: URL?
    ) throws -> PTYHandle {
        var masterFD: Int32 = -1
        var slaveFD: Int32 = -1

        // Build filtered environment
        var filteredEnv = environment.filter { allowedEnvVars.contains($0.key) }
        filteredEnv["TERM"] = "xterm-256color"
        filteredEnv["COLORTERM"] = "truecolor"
        filteredEnv["TERM_PROGRAM"] = "ArcNext"

        // Set up window size
        var winSize = winsize(ws_row: 24, ws_col: 80, ws_xpixel: 0, ws_ypixel: 0)

        let pid = forkpty(&masterFD, nil, nil, &winSize)

        guard pid >= 0 else {
            throw PTYError.forkFailed(errno: errno)
        }

        if pid == 0 {
            // Child process
            if let workingDirectory {
                _ = chdir(workingDirectory.path)
            }

            // Set environment
            for (key, value) in filteredEnv {
                setenv(key, value, 1)
            }

            // Build argv
            let argv = ([shell] + arguments).map { strdup($0) } + [nil]
            execvp(shell, argv)
            // If exec fails, exit child
            _exit(1)
        }

        // Parent process
        slaveFD = -1 // slave FD is only valid in child after forkpty
        return PTYHandle(masterFD: masterFD, slaveFD: slaveFD, pid: pid)
    }

    public func resize(handle: PTYHandle, cols: UInt16, rows: UInt16) throws {
        var winSize = winsize(ws_row: rows, ws_col: cols, ws_xpixel: 0, ws_ypixel: 0)
        guard ioctl(handle.masterFD, TIOCSWINSZ, &winSize) == 0 else {
            throw PTYError.resizeFailed(errno: errno)
        }
    }

    public func terminate(handle: PTYHandle) {
        kill(handle.pid, SIGHUP)
    }
}

public enum PTYError: Error, Sendable {
    case forkFailed(errno: Int32)
    case resizeFailed(errno: Int32)
    case notConnected
}

import AppKit
import ArcNextCore
import SwiftTerm

/// AppKit container that hosts a SwiftTerm TerminalView for a given session.
public final class TerminalContainerView: NSView {
    private var terminalView: TerminalView?
    private let session: TerminalSession

    public init(session: TerminalSession) {
        self.session = session
        super.init(frame: .zero)
        setupTerminal()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupTerminal() {
        let terminal = TerminalView(frame: bounds)
        terminal.autoresizingMask = [.width, .height]
        terminal.translatesAutoresizingMaskIntoConstraints = true

        // Apply profile settings
        let profile = session.profile
        if let font = NSFont(name: profile.fontFamily, size: profile.fontSize) {
            terminal.font = font
        }

        addSubview(terminal)
        terminalView = terminal

        // Connect to PTY if we have a handle
        if let handle = session.ptyHandle {
            connectToPTY(handle)
        }
    }

    private func connectToPTY(_ handle: PTYHandle) {
        guard let terminalView else { return }

        // Set up read loop from PTY master FD
        let source = DispatchSource.makeReadSource(
            fileDescriptor: handle.masterFD,
            queue: .global(qos: .userInteractive)
        )
        source.setEventHandler { [weak self] in
            guard let self else { return }
            var buffer = [UInt8](repeating: 0, count: 8192)
            let bytesRead = read(handle.masterFD, &buffer, buffer.count)
            if bytesRead > 0 {
                let data = buffer[0 ..< bytesRead]
                DispatchQueue.main.async {
                    terminalView.feed(byteArray: data)
                }
            }
        }
        source.resume()
    }

    public override func layout() {
        super.layout()
        terminalView?.frame = bounds
    }
}

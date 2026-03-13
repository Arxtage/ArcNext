import AppKit
import ArcNextCore

public final class MainWindow: NSWindow {
    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isMovableByWindowBackground = true
        minSize = NSSize(width: 600, height: 400)
        setFrameAutosaveName("ArcNextMainWindow")
        backgroundColor = .black
    }
}

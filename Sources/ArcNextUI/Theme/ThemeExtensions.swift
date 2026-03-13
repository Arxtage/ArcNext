import AppKit
import ArcNextCore
import SwiftTerm

extension CodableColor {
    public var nsColor: NSColor {
        NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension Theme {
    @MainActor public func apply(to view: LocalProcessTerminalView) {
        view.nativeBackgroundColor = backgroundColor.nsColor
        view.nativeForegroundColor = foregroundColor.nsColor
        view.caretColor = cursorColor.nsColor
        view.selectedTextBackgroundColor = selectionColor.nsColor

        if let font = NSFont(name: fontFamily, size: fontSize) {
            view.font = font
        }
    }
}

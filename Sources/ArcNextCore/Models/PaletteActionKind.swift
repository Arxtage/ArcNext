import Foundation

/// Actions that can be triggered from the universal palette.
public enum PaletteActionKind: Sendable {
    case switchTab(UUID)
    case reopenTab
    case openDirectory(URL)
    case newTerminal
    case splitVertical
    case splitHorizontal
}

import Foundation

public struct TerminalProfile: Codable, Sendable, Equatable {
    public var fontFamily: String
    public var fontSize: Double
    public var cursorStyle: CursorStyle
    public var scrollbackLines: Int
    public var theme: Theme

    public init(
        fontFamily: String = "SF Mono",
        fontSize: Double = 13,
        cursorStyle: CursorStyle = .block,
        scrollbackLines: Int = 10_000,
        theme: Theme = .default
    ) {
        self.fontFamily = fontFamily
        self.fontSize = fontSize
        self.cursorStyle = cursorStyle
        self.scrollbackLines = scrollbackLines
        self.theme = theme
    }

    public static let `default` = TerminalProfile()
}

public enum CursorStyle: String, Codable, Sendable {
    case block
    case underline
    case bar
}

import Foundation

/// Types whose appearance can be customized via a theme.
public protocol Themeable {
    func apply(theme: Theme)
}

public struct Theme: Codable, Sendable, Equatable {
    public var name: String
    public var backgroundColor: CodableColor
    public var foregroundColor: CodableColor
    public var cursorColor: CodableColor
    public var selectionColor: CodableColor
    public var ansiColors: [CodableColor]
    public var fontFamily: String
    public var fontSize: Double

    public init(
        name: String,
        backgroundColor: CodableColor,
        foregroundColor: CodableColor,
        cursorColor: CodableColor,
        selectionColor: CodableColor,
        ansiColors: [CodableColor],
        fontFamily: String,
        fontSize: Double
    ) {
        self.name = name
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.cursorColor = cursorColor
        self.selectionColor = selectionColor
        self.ansiColors = ansiColors
        self.fontFamily = fontFamily
        self.fontSize = fontSize
    }

    public static let `default` = Theme(
        name: "Default Dark",
        backgroundColor: CodableColor(red: 0.1, green: 0.1, blue: 0.1),
        foregroundColor: CodableColor(red: 0.9, green: 0.9, blue: 0.9),
        cursorColor: CodableColor(red: 0.9, green: 0.9, blue: 0.9),
        selectionColor: CodableColor(red: 0.3, green: 0.3, blue: 0.5),
        ansiColors: [],
        fontFamily: "SF Mono",
        fontSize: 13
    )
}

public struct CodableColor: Codable, Sendable, Equatable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

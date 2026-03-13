import Foundation

@Observable
public final class TabGroup: Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var color: GroupColor
    public var isCollapsed: Bool
    public var tabIDs: [UUID]

    public init(
        id: UUID = UUID(),
        name: String,
        color: GroupColor = .blue,
        isCollapsed: Bool = false,
        tabIDs: [UUID] = []
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.isCollapsed = isCollapsed
        self.tabIDs = tabIDs
    }
}

public enum GroupColor: String, Codable, CaseIterable, Sendable {
    case red
    case orange
    case yellow
    case green
    case blue
    case purple
    case pink
    case gray
}

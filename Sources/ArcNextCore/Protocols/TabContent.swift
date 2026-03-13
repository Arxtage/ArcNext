import Foundation

/// Anything that can live inside a tab: terminal, browser, dashboard, etc.
/// This is the primary extensibility point for P2/P3 content types.
public protocol TabContent: Identifiable, Sendable {
    var id: UUID { get }
    var title: String { get }
    var contentType: TabContentType { get }
}

public enum TabContentType: String, Codable, Sendable {
    case terminal
    case browser
    case dashboard
}

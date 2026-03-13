import Foundation

@Observable
public final class Pane: Identifiable, Codable {
    public let id: UUID
    public var tabStack: [UUID]
    public var activeTabIndex: Int

    public init(
        id: UUID = UUID(),
        tabStack: [UUID] = [],
        activeTabIndex: Int = 0
    ) {
        self.id = id
        self.tabStack = tabStack
        self.activeTabIndex = activeTabIndex
    }

    public var activeTabID: UUID? {
        guard activeTabIndex >= 0, activeTabIndex < tabStack.count else { return nil }
        return tabStack[activeTabIndex]
    }

    public func pushTab(_ tabID: UUID) {
        tabStack.append(tabID)
        activeTabIndex = tabStack.count - 1
    }

    public func removeTab(_ tabID: UUID) {
        tabStack.removeAll { $0 == tabID }
        activeTabIndex = min(activeTabIndex, max(0, tabStack.count - 1))
    }
}

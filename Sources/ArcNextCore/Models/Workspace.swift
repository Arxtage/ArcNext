import Foundation

@Observable
public final class Workspace: Identifiable, Codable {
    public let id: UUID
    public var tabs: [UUID: Tab]
    public var tabGroups: [TabGroup]
    public var ungroupedTabIDs: [UUID]
    public var panes: [UUID: Pane]
    public var activeTabID: UUID?
    public var activePaneID: UUID?
    public var splitConfiguration: SplitNode?

    public init(
        id: UUID = UUID(),
        tabs: [UUID: Tab] = [:],
        tabGroups: [TabGroup] = [],
        ungroupedTabIDs: [UUID] = [],
        panes: [UUID: Pane] = [:],
        activeTabID: UUID? = nil,
        activePaneID: UUID? = nil,
        splitConfiguration: SplitNode? = nil
    ) {
        self.id = id
        self.tabs = tabs
        self.tabGroups = tabGroups
        self.ungroupedTabIDs = ungroupedTabIDs
        self.panes = panes
        self.activeTabID = activeTabID
        self.activePaneID = activePaneID
        self.splitConfiguration = splitConfiguration
    }

    // MARK: - Tab management

    public func addTab(_ tab: Tab, toGroup groupID: UUID? = nil) {
        tabs[tab.id] = tab
        if let groupID, let group = tabGroups.first(where: { $0.id == groupID }) {
            tab.groupID = groupID
            group.tabIDs.append(tab.id)
        } else {
            ungroupedTabIDs.append(tab.id)
        }
    }

    public func removeTab(_ tabID: UUID) {
        guard let tab = tabs[tabID] else { return }
        if let groupID = tab.groupID,
           let group = tabGroups.first(where: { $0.id == groupID }) {
            group.tabIDs.removeAll { $0 == tabID }
        } else {
            ungroupedTabIDs.removeAll { $0 == tabID }
        }
        for pane in panes.values {
            pane.removeTab(tabID)
        }
        tabs.removeValue(forKey: tabID)
        if activeTabID == tabID {
            activeTabID = ungroupedTabIDs.first ?? tabGroups.first?.tabIDs.first
        }
    }

    // MARK: - Group management

    public func addGroup(_ group: TabGroup) {
        tabGroups.append(group)
    }

    public func removeGroup(_ groupID: UUID) {
        guard let index = tabGroups.firstIndex(where: { $0.id == groupID }) else { return }
        let group = tabGroups[index]
        // Move tabs to ungrouped
        for tabID in group.tabIDs {
            tabs[tabID]?.groupID = nil
            ungroupedTabIDs.append(tabID)
        }
        tabGroups.remove(at: index)
    }

    public func moveTab(_ tabID: UUID, toGroup groupID: UUID?) {
        guard let tab = tabs[tabID] else { return }
        // Remove from current location
        if let oldGroupID = tab.groupID,
           let oldGroup = tabGroups.first(where: { $0.id == oldGroupID }) {
            oldGroup.tabIDs.removeAll { $0 == tabID }
        } else {
            ungroupedTabIDs.removeAll { $0 == tabID }
        }
        // Add to new location
        if let groupID, let group = tabGroups.first(where: { $0.id == groupID }) {
            tab.groupID = groupID
            group.tabIDs.append(tabID)
        } else {
            tab.groupID = nil
            ungroupedTabIDs.append(tabID)
        }
    }

    // MARK: - Pane management

    public func addPane(_ pane: Pane) {
        panes[pane.id] = pane
        if activePaneID == nil {
            activePaneID = pane.id
        }
    }

    public func removePane(_ paneID: UUID) {
        panes.removeValue(forKey: paneID)
        splitConfiguration = splitConfiguration?.removePane(paneID)
        if activePaneID == paneID {
            activePaneID = panes.keys.first
        }
    }

    // MARK: - Ordered tabs for sidebar display

    public var allOrderedTabIDs: [UUID] {
        var result: [UUID] = []
        for group in tabGroups {
            result.append(contentsOf: group.tabIDs)
        }
        result.append(contentsOf: ungroupedTabIDs)
        return result
    }
}

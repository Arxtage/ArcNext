import Foundation

/// Manages tab groups (Tidy). P1: manual groups only. P2: auto-tidy.
@Observable
public final class TidyService {
    public let workspace: Workspace

    public init(workspace: Workspace) {
        self.workspace = workspace
    }

    @discardableResult
    public func createGroup(name: String, color: GroupColor = .blue) -> TabGroup {
        let group = TabGroup(name: name, color: color)
        workspace.addGroup(group)
        return group
    }

    public func deleteGroup(_ groupID: UUID) {
        workspace.removeGroup(groupID)
    }

    public func renameGroup(_ groupID: UUID, to name: String) {
        guard let group = workspace.tabGroups.first(where: { $0.id == groupID }) else { return }
        group.name = name
    }

    public func setGroupColor(_ groupID: UUID, color: GroupColor) {
        guard let group = workspace.tabGroups.first(where: { $0.id == groupID }) else { return }
        group.color = color
    }

    public func toggleGroupCollapsed(_ groupID: UUID) {
        guard let group = workspace.tabGroups.first(where: { $0.id == groupID }) else { return }
        group.isCollapsed.toggle()
    }

    public func moveTabToGroup(_ tabID: UUID, groupID: UUID?) {
        workspace.moveTab(tabID, toGroup: groupID)
    }

    public func reorderTabInGroup(_ tabID: UUID, toIndex index: Int) {
        guard let tab = workspace.tabs[tabID],
              let groupID = tab.groupID,
              let group = workspace.tabGroups.first(where: { $0.id == groupID }) else { return }
        group.tabIDs.removeAll { $0 == tabID }
        let clampedIndex = min(index, group.tabIDs.count)
        group.tabIDs.insert(tabID, at: clampedIndex)
    }
}

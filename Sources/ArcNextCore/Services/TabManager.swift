import Foundation

/// Manages tab creation, switching, closing, and reopen stack.
@Observable
public final class TabManager {
    public let workspace: Workspace
    public private(set) var recentlyClosed: [Tab] = []
    private let maxRecentlyClosed = 20

    public init(workspace: Workspace) {
        self.workspace = workspace
    }

    @discardableResult
    public func createTab(
        title: String,
        contentType: TabContentType = .terminal,
        contentID: UUID,
        inGroup groupID: UUID? = nil,
        inPane paneID: UUID? = nil
    ) -> Tab {
        let tab = Tab(
            title: title,
            contentType: contentType,
            contentID: contentID
        )
        workspace.addTab(tab, toGroup: groupID)

        // Add to pane if specified, otherwise to first available pane
        if let paneID, let pane = workspace.panes[paneID] {
            pane.pushTab(tab.id)
        } else if let firstPane = workspace.panes.values.first {
            firstPane.pushTab(tab.id)
        }

        workspace.activeTabID = tab.id
        return tab
    }

    public func closeTab(_ tabID: UUID) {
        guard let tab = workspace.tabs[tabID] else { return }
        recentlyClosed.insert(tab, at: 0)
        if recentlyClosed.count > maxRecentlyClosed {
            recentlyClosed.removeLast()
        }
        workspace.removeTab(tabID)
    }

    public func reopenLastClosed() -> Tab? {
        guard let tab = recentlyClosed.first else { return nil }
        recentlyClosed.removeFirst()
        workspace.addTab(tab)
        if let firstPane = workspace.panes.values.first {
            firstPane.pushTab(tab.id)
        }
        workspace.activeTabID = tab.id
        return tab
    }

    public func switchToTab(_ tabID: UUID) {
        guard let tab = workspace.tabs[tabID] else { return }
        tab.touch()
        if let pane = workspace.panes.values.first(where: { $0.tabStack.contains(tabID) }),
           let index = pane.tabStack.firstIndex(of: tabID) {
            pane.activeTabIndex = index
            workspace.activePaneID = pane.id
        }
        workspace.activeTabID = tabID
    }

    public func pinTab(_ tabID: UUID) {
        workspace.tabs[tabID]?.isPinned = true
    }

    public func unpinTab(_ tabID: UUID) {
        workspace.tabs[tabID]?.isPinned = false
    }
}

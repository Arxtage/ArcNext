import Foundation
import Testing

@testable import ArcNextCore

@Suite("TabManager")
struct TabManagerTests {
    @Test("Create tab adds to workspace")
    func createTab() {
        let workspace = Workspace()
        let pane = Pane()
        workspace.addPane(pane)
        let manager = TabManager(workspace: workspace)

        let tab = manager.createTab(title: "Test", contentID: UUID(), inPane: pane.id)
        #expect(workspace.tabs[tab.id] != nil)
        #expect(workspace.activeTabID == tab.id)
        #expect(pane.tabStack.contains(tab.id))
    }

    @Test("Close tab moves to recently closed")
    func closeTab() {
        let workspace = Workspace()
        let pane = Pane()
        workspace.addPane(pane)
        let manager = TabManager(workspace: workspace)

        let tab = manager.createTab(title: "Test", contentID: UUID(), inPane: pane.id)
        manager.closeTab(tab.id)
        #expect(workspace.tabs[tab.id] == nil)
        #expect(manager.recentlyClosed.count == 1)
    }

    @Test("Reopen last closed tab")
    func reopenTab() {
        let workspace = Workspace()
        let pane = Pane()
        workspace.addPane(pane)
        let manager = TabManager(workspace: workspace)

        let tab = manager.createTab(title: "Closed", contentID: UUID(), inPane: pane.id)
        manager.closeTab(tab.id)
        #expect(manager.recentlyClosed.count == 1)

        let reopened = manager.reopenLastClosed()
        #expect(reopened != nil)
        #expect(reopened?.title == "Closed")
        #expect(manager.recentlyClosed.isEmpty)
    }

    @Test("Switch to tab updates activeTabID")
    func switchTab() {
        let workspace = Workspace()
        let pane1 = Pane()
        let pane2 = Pane()
        workspace.addPane(pane1)
        workspace.addPane(pane2)
        let manager = TabManager(workspace: workspace)

        let tab1 = manager.createTab(title: "First", contentID: UUID(), inPane: pane1.id)
        let tab2 = manager.createTab(title: "Second", contentID: UUID(), inPane: pane1.id)
        let tab3 = manager.createTab(title: "Third", contentID: UUID(), inPane: pane2.id)
        #expect(workspace.activeTabID == tab3.id)

        manager.switchToTab(tab1.id)
        #expect(workspace.activeTabID == tab1.id)
        #expect(workspace.activePaneID == pane1.id)
        #expect(pane1.activeTabID == tab1.id)

        manager.switchToTab(tab3.id)
        #expect(workspace.activeTabID == tab3.id)
        #expect(workspace.activePaneID == pane2.id)
        #expect(pane2.activeTabID == tab3.id)

        _ = tab2
    }

    @Test("Pin and unpin tab")
    func pinTab() {
        let workspace = Workspace()
        let pane = Pane()
        workspace.addPane(pane)
        let manager = TabManager(workspace: workspace)

        let tab = manager.createTab(title: "Test", contentID: UUID(), inPane: pane.id)
        #expect(tab.isPinned == false)

        manager.pinTab(tab.id)
        #expect(workspace.tabs[tab.id]?.isPinned == true)

        manager.unpinTab(tab.id)
        #expect(workspace.tabs[tab.id]?.isPinned == false)
    }
}

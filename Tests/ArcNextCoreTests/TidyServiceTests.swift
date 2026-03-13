import Foundation
import Testing

@testable import ArcNextCore

@Suite("TidyService")
struct TidyServiceTests {
    @Test("Create group adds to workspace")
    func createGroup() {
        let workspace = Workspace()
        let service = TidyService(workspace: workspace)

        let group = service.createGroup(name: "Work", color: .blue)
        #expect(workspace.tabGroups.count == 1)
        #expect(workspace.tabGroups.first?.name == "Work")
        #expect(group.color == .blue)
    }

    @Test("Delete group moves tabs to ungrouped")
    func deleteGroup() {
        let workspace = Workspace()
        let pane = Pane()
        workspace.addPane(pane)
        let tabManager = TabManager(workspace: workspace)
        let service = TidyService(workspace: workspace)

        let group = service.createGroup(name: "Temp")
        let tab = tabManager.createTab(title: "Tab1", contentID: UUID(), inGroup: group.id, inPane: pane.id)

        #expect(workspace.tabs[tab.id]?.groupID == group.id)
        service.deleteGroup(group.id)
        #expect(workspace.tabGroups.isEmpty)
        #expect(workspace.ungroupedTabIDs.contains(tab.id))
        #expect(workspace.tabs[tab.id]?.groupID == nil)
    }

    @Test("Rename group")
    func renameGroup() {
        let workspace = Workspace()
        let service = TidyService(workspace: workspace)

        let group = service.createGroup(name: "Old")
        service.renameGroup(group.id, to: "New")
        #expect(workspace.tabGroups.first?.name == "New")
    }

    @Test("Toggle group collapsed")
    func toggleCollapsed() {
        let workspace = Workspace()
        let service = TidyService(workspace: workspace)

        let group = service.createGroup(name: "Test")
        #expect(group.isCollapsed == false)

        service.toggleGroupCollapsed(group.id)
        #expect(workspace.tabGroups.first?.isCollapsed == true)

        service.toggleGroupCollapsed(group.id)
        #expect(workspace.tabGroups.first?.isCollapsed == false)
    }

    @Test("Move tab between groups")
    func moveTabBetweenGroups() {
        let workspace = Workspace()
        let pane = Pane()
        workspace.addPane(pane)
        let tabManager = TabManager(workspace: workspace)
        let service = TidyService(workspace: workspace)

        let group1 = service.createGroup(name: "Group1")
        let group2 = service.createGroup(name: "Group2")
        let tab = tabManager.createTab(title: "Tab", contentID: UUID(), inGroup: group1.id, inPane: pane.id)

        #expect(group1.tabIDs.contains(tab.id))
        service.moveTabToGroup(tab.id, groupID: group2.id)
        #expect(!group1.tabIDs.contains(tab.id))
        #expect(group2.tabIDs.contains(tab.id))
        #expect(workspace.tabs[tab.id]?.groupID == group2.id)
    }
}

import Foundation
import Testing

@testable import ArcNextCore

@Suite("Workspace")
struct WorkspaceTests {
    @Test("visible split tabs follow split order")
    func visibleSplitTabsFollowSplitOrder() {
        let workspace = Workspace()
        let pane1 = Pane()
        let pane2 = Pane()
        let pane3 = Pane()

        workspace.addPane(pane1)
        workspace.addPane(pane2)
        workspace.addPane(pane3)

        let tab1 = Tab(title: "First", contentID: UUID())
        let tab2 = Tab(title: "Second", contentID: UUID())
        let tab3 = Tab(title: "Third", contentID: UUID())

        workspace.addTab(tab1)
        workspace.addTab(tab2)
        workspace.addTab(tab3)

        pane1.pushTab(tab1.id)
        pane2.pushTab(tab2.id)
        pane3.pushTab(tab3.id)

        workspace.splitConfiguration = .split(
            direction: .vertical,
            ratio: 0.5,
            first: .leaf(paneID: pane1.id),
            second: .split(
                direction: .horizontal,
                ratio: 0.5,
                first: .leaf(paneID: pane2.id),
                second: .leaf(paneID: pane3.id)
            )
        )

        #expect(workspace.visibleSplitTabIDs == [tab1.id, tab2.id, tab3.id])
    }

    @Test("visible split tabs stay hidden for single pane")
    func visibleSplitTabsRequireMultiplePanes() {
        let workspace = Workspace()
        let pane = Pane()
        workspace.addPane(pane)

        let tab = Tab(title: "Solo", contentID: UUID())
        workspace.addTab(tab)
        pane.pushTab(tab.id)
        workspace.splitConfiguration = .leaf(paneID: pane.id)

        #expect(workspace.visibleSplitTabIDs.isEmpty)
    }
}

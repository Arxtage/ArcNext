import Testing
@testable import ArcNextCore

@Suite("AppState")
struct AppStateTests {

    @Test("newTerminalTab creates tab and session")
    func newTerminalTabCreatesTabAndSession() {
        let state = AppState()
        let pane = Pane()
        state.workspace.addPane(pane)
        state.workspace.splitConfiguration = .leaf(paneID: pane.id)

        let tab = state.newTerminalTab(inPane: pane.id)
        #expect(state.workspace.tabs[tab.id] != nil)
        #expect(state.sessionManager.sessions[tab.contentID] != nil)
        #expect(tab.contentType == .terminal)
    }

    @Test("closeTab removes tab and session")
    func closeTabRemovesTabAndSession() {
        let state = AppState()
        let pane = Pane()
        state.workspace.addPane(pane)

        let tab = state.newTerminalTab(inPane: pane.id)
        let sessionID = tab.contentID

        state.closeTab(tab.id)
        #expect(state.workspace.tabs[tab.id] == nil)
        #expect(state.sessionManager.sessions[sessionID] == nil)
    }

    @Test("splitActivePane creates new pane and updates split config")
    func splitActivePaneCreatesSplit() {
        let state = AppState()
        let pane = Pane()
        state.workspace.addPane(pane)
        state.workspace.splitConfiguration = .leaf(paneID: pane.id)

        let tab = state.newTerminalTab(inPane: pane.id)
        state.workspace.activeTabID = tab.id

        state.splitActivePane(direction: .vertical)

        #expect(state.workspace.panes.count == 2)
        #expect(state.workspace.splitConfiguration?.paneCount == 2)
    }

    @Test("activePaneID set on split")
    func activePaneIDSetOnSplit() {
        let state = AppState()
        let pane = Pane()
        state.workspace.addPane(pane)
        state.workspace.activePaneID = pane.id
        state.workspace.splitConfiguration = .leaf(paneID: pane.id)

        let tab = state.newTerminalTab(inPane: pane.id)
        state.workspace.activeTabID = tab.id

        state.splitActivePane(direction: .vertical)

        // activePaneID should now point to the new pane, not the original
        #expect(state.workspace.activePaneID != nil)
        #expect(state.workspace.activePaneID != pane.id)
    }

    @Test("activePaneID falls back on removePane")
    func activePaneIDFallsBackOnRemove() {
        let state = AppState()
        let pane1 = Pane()
        let pane2 = Pane()
        state.workspace.addPane(pane1)
        state.workspace.addPane(pane2)
        state.workspace.activePaneID = pane1.id

        state.workspace.removePane(pane1.id)

        #expect(state.workspace.activePaneID == pane2.id)
    }

    @Test("executePaletteAction newTerminal creates a tab")
    func paletteNewTerminal() {
        let state = AppState()
        let pane = Pane()
        state.workspace.addPane(pane)

        state.executePaletteAction(.newTerminal)

        #expect(state.workspace.tabs.count == 1)
    }
}

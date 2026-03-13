import Foundation

/// Single source of truth for the entire app.
@Observable
public final class AppState {
    public let workspace: Workspace
    public let sessionManager: SessionManager
    public let tabManager: TabManager
    public let tidyService: TidyService
    public let directoryTracker: DirectoryTracker
    public var isPaletteVisible: Bool = false

    public init() {
        let workspace = Workspace()
        self.workspace = workspace
        self.sessionManager = SessionManager()
        self.tabManager = TabManager(workspace: workspace)
        self.tidyService = TidyService(workspace: workspace)
        self.directoryTracker = DirectoryTracker()
    }

    /// Create a new terminal tab, optionally in a specific directory.
    @discardableResult
    public func newTerminalTab(
        workingDirectory: URL? = nil,
        inGroup groupID: UUID? = nil,
        inPane paneID: UUID? = nil
    ) -> Tab {
        let session = sessionManager.createSession(workingDirectory: workingDirectory)
        let title = workingDirectory?.lastPathComponent ?? "Terminal"
        let tab = tabManager.createTab(
            title: title,
            contentType: .terminal,
            contentID: session.id,
            inGroup: groupID,
            inPane: paneID
        )
        if let dir = workingDirectory {
            directoryTracker.recordDirectory(dir)
        }
        return tab
    }

    /// Split the active pane.
    public func splitActivePane(direction: SplitDirection) {
        guard let activeTabID = workspace.activeTabID else { return }

        // Find the pane containing the active tab
        guard let activePaneEntry = workspace.panes.first(where: { $0.value.tabStack.contains(activeTabID) }) else {
            return
        }

        // Create new pane with a new terminal
        let newPane = Pane()
        workspace.addPane(newPane)

        let session = sessionManager.createSession()
        let tab = tabManager.createTab(
            title: "Terminal",
            contentType: .terminal,
            contentID: session.id,
            inPane: newPane.id
        )
        _ = tab

        workspace.activePaneID = newPane.id

        if let splitConfig = workspace.splitConfiguration {
            workspace.splitConfiguration = splitConfig.insertSplit(
                at: activePaneEntry.key,
                newPaneID: newPane.id,
                direction: direction
            )
        } else {
            workspace.splitConfiguration = .split(
                direction: direction,
                ratio: 0.5,
                first: .leaf(paneID: activePaneEntry.key),
                second: .leaf(paneID: newPane.id)
            )
        }
    }

    /// Execute a palette action.
    public func executePaletteAction(_ action: PaletteActionKind) {
        switch action {
        case .switchTab(let tabID):
            tabManager.switchToTab(tabID)
        case .reopenTab:
            _ = tabManager.reopenLastClosed()
        case .openDirectory(let url):
            newTerminalTab(workingDirectory: url)
        case .newTerminal:
            newTerminalTab()
        case .splitVertical:
            splitActivePane(direction: .vertical)
        case .splitHorizontal:
            splitActivePane(direction: .horizontal)
        }
    }

    // MARK: - Tab Close

    public func closeTab(_ tabID: UUID) {
        guard let tab = workspace.tabs[tabID] else { return }
        sessionManager.closeSession(tab.contentID)
        tabManager.closeTab(tabID)

        if workspace.tabs.isEmpty {
            let pane = Pane()
            workspace.addPane(pane)
            workspace.splitConfiguration = .leaf(paneID: pane.id)
            newTerminalTab(inPane: pane.id)
        }
    }

    // MARK: - Session Restore

    private var saveURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("ArcNext", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("workspace.json")
    }

    public func saveWorkspace() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(workspace) else { return }
        try? data.write(to: saveURL)
    }

    public func restoreWorkspace() {
        guard let data = try? Data(contentsOf: saveURL),
              let restored = try? JSONDecoder().decode(Workspace.self, from: data) else { return }
        // Merge restored state into current workspace
        for (id, tab) in restored.tabs {
            workspace.tabs[id] = tab
            // Create stopped session so the view can reconnect
            let session = TerminalSession(id: tab.contentID, state: .stopped)
            sessionManager.sessions[session.id] = session
        }
        for group in restored.tabGroups {
            workspace.tabGroups.append(group)
        }
        workspace.ungroupedTabIDs = restored.ungroupedTabIDs
        workspace.activeTabID = restored.activeTabID
        workspace.activePaneID = restored.activePaneID
        workspace.splitConfiguration = restored.splitConfiguration
        for (id, pane) in restored.panes {
            workspace.panes[id] = pane
        }
    }
}

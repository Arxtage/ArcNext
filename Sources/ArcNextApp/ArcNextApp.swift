import AppKit
import ArcNextCore
import ArcNextUI

@main @MainActor
struct ArcNextApp {
    static let appState = AppState()
    static var windowController: MainWindowController?

    static func main() {
        let app = NSApplication.shared
        let delegate = ArcNextAppDelegate(appState: appState)
        app.delegate = delegate
        app.run()
    }
}

final class ArcNextAppDelegate: NSObject, NSApplicationDelegate {
    let appState: AppState
    var windowController: MainWindowController?

    init(appState: AppState) {
        self.appState = appState
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Restore previous workspace
        appState.restoreWorkspace()

        // Ensure at least one tab exists
        if appState.workspace.tabs.isEmpty {
            let pane = Pane()
            appState.workspace.addPane(pane)
            appState.workspace.activePaneID = pane.id
            if appState.workspace.splitConfiguration == nil {
                appState.workspace.splitConfiguration = .leaf(paneID: pane.id)
            }
            appState.newTerminalTab(inPane: pane.id)
        }

        windowController = MainWindowController(appState: appState)
        windowController?.showWindow(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        appState.saveWorkspace()
        appState.sessionManager.closeAll()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

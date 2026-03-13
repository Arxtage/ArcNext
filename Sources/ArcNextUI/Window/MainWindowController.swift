import AppKit
import ArcNextCore
import SwiftTerm
import SwiftUI

public final class MainWindowController: NSWindowController, NSSplitViewDelegate {
    private let appState: AppState
    nonisolated(unsafe) private var eventMonitor: Any?

    public init(appState: AppState) {
        self.appState = appState
        let window = MainWindow(contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800))
        super.init(window: window)
        setupContent()
        setupKeyboardShortcuts()
        window.center()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        let monitor = eventMonitor
        eventMonitor = nil
        if let monitor {
            MainActor.assumeIsolated {
                NSEvent.removeMonitor(monitor)
            }
        }
    }

    private func setupContent() {
        guard let window else { return }

        let splitView = NSSplitView()
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.autosaveName = "ArcNextSidebar"
        splitView.delegate = self

        // Sidebar (SwiftUI embedded in AppKit)
        let sidebarView = SidebarView(appState: appState)
        let sidebarHost = NSHostingView(rootView: sidebarView)
        sidebarHost.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        splitView.addArrangedSubview(sidebarHost)

        // Main content area (SwiftUI: splits + palette overlay)
        let contentView = SplitContainerView(appState: appState)
        splitView.addArrangedSubview(contentView)

        // Set sidebar width constraints
        sidebarHost.widthAnchor.constraint(greaterThanOrEqualToConstant: 180).isActive = true
        sidebarHost.widthAnchor.constraint(lessThanOrEqualToConstant: 350).isActive = true

        window.contentView = splitView

        // Set initial sidebar position (autosave will override if a saved position exists)
        splitView.setPosition(220, ofDividerAt: 0)
    }

    private func setupKeyboardShortcuts() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if self.handleKeyEvent(event) {
                return nil // consumed
            }
            return event
        }
    }

    private func handleTerminalKeyEvent(_ event: NSEvent) -> Bool {
        guard let terminalView = window?.firstResponder as? LocalProcessTerminalView else {
            return false
        }

        let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        switch (event.keyCode, mods) {
        case (51, [.command]):
            // Cmd+Backspace → Ctrl+U (kill line)
            terminalView.getTerminal().sendResponse([UInt8(0x15)])
            return true
        case (51, [.option]):
            // Opt+Backspace → Ctrl+W (delete word backward)
            terminalView.getTerminal().sendResponse([UInt8(0x17)])
            return true
        case (123, [.command]):
            // Cmd+Left → Ctrl+A (beginning of line)
            terminalView.getTerminal().sendResponse([UInt8(0x01)])
            return true
        case (124, [.command]):
            // Cmd+Right → Ctrl+E (end of line)
            terminalView.getTerminal().sendResponse([UInt8(0x05)])
            return true
        default:
            return false
        }
    }

    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        if handleTerminalKeyEvent(event) {
            return true
        }

        guard event.modifierFlags.contains(.command) else { return false }

        let hasShift = event.modifierFlags.contains(.shift)

        switch event.charactersIgnoringModifiers {
        case "t":
            appState.isPaletteVisible.toggle()
            return true
        case "d":
            if hasShift {
                appState.splitActivePane(direction: .horizontal)
            } else {
                appState.splitActivePane(direction: .vertical)
            }
            return true
        case "w":
            if let activeTabID = appState.workspace.activeTabID {
                appState.closeTab(activeTabID)
            }
            return true
        case "[":
            cycleTabs(forward: false)
            return true
        case "]":
            cycleTabs(forward: true)
            return true
        default:
            // Cmd+1 through Cmd+9
            if let char = event.charactersIgnoringModifiers?.first,
               let digit = char.wholeNumberValue, digit >= 1, digit <= 9 {
                switchToTabByIndex(digit - 1)
                return true
            }
            return false
        }
    }

    private func cycleTabs(forward: Bool) {
        let orderedIDs = appState.workspace.allOrderedTabIDs
        guard !orderedIDs.isEmpty else { return }
        guard let activeID = appState.workspace.activeTabID,
              let currentIndex = orderedIDs.firstIndex(of: activeID) else {
            appState.tabManager.switchToTab(orderedIDs[0])
            return
        }
        let nextIndex: Int
        if forward {
            nextIndex = (currentIndex + 1) % orderedIDs.count
        } else {
            nextIndex = (currentIndex - 1 + orderedIDs.count) % orderedIDs.count
        }
        appState.tabManager.switchToTab(orderedIDs[nextIndex])
    }

    private func switchToTabByIndex(_ index: Int) {
        let orderedIDs = appState.workspace.allOrderedTabIDs
        guard index < orderedIDs.count else { return }
        appState.tabManager.switchToTab(orderedIDs[index])
    }

    public func showPalette() {
        appState.isPaletteVisible = true
    }

    // MARK: - NSSplitViewDelegate

    public func splitView(
        _ splitView: NSSplitView,
        constrainMinCoordinate proposedMinimumPosition: CGFloat,
        ofSubviewAt dividerIndex: Int
    ) -> CGFloat {
        dividerIndex == 0 ? 180 : proposedMinimumPosition
    }

    public func splitView(
        _ splitView: NSSplitView,
        constrainMaxCoordinate proposedMaximumPosition: CGFloat,
        ofSubviewAt dividerIndex: Int
    ) -> CGFloat {
        dividerIndex == 0 ? 350 : proposedMaximumPosition
    }
}

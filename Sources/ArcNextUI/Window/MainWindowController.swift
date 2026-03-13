import AppKit
import ArcNextCore
import SwiftUI

public final class MainWindowController: NSWindowController {
    private let appState: AppState

    public init(appState: AppState) {
        self.appState = appState
        let window = MainWindow(contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800))
        super.init(window: window)
        setupContent()
        window.center()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupContent() {
        guard let window else { return }

        let splitView = NSSplitView()
        splitView.isVertical = true
        splitView.dividerStyle = .thin

        // Sidebar (SwiftUI embedded in AppKit)
        let sidebarView = SidebarView(appState: appState)
        let sidebarHost = NSHostingView(rootView: sidebarView)
        sidebarHost.setContentHuggingPriority(NSLayoutConstraint.Priority.defaultHigh, for: NSLayoutConstraint.Orientation.horizontal)
        splitView.addArrangedSubview(sidebarHost)

        // Main content area
        let contentView = SplitContainerView(appState: appState)
        splitView.addArrangedSubview(contentView)

        // Set sidebar width constraints
        sidebarHost.widthAnchor.constraint(greaterThanOrEqualToConstant: 180).isActive = true
        sidebarHost.widthAnchor.constraint(lessThanOrEqualToConstant: 350).isActive = true

        window.contentView = splitView
    }

    public func showPalette() {
        appState.isPaletteVisible = true
    }
}

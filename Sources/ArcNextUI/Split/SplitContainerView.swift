import AppKit
import ArcNextCore

/// Maps a SplitNode binary tree to a nested NSSplitView hierarchy.
public final class SplitContainerView: NSView {
    private let appState: AppState

    public init(appState: AppState) {
        self.appState = appState
        super.init(frame: .zero)
        rebuildLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func rebuildLayout() {
        subviews.forEach { $0.removeFromSuperview() }

        guard let splitConfig = appState.workspace.splitConfiguration else {
            // No splits — show single pane or placeholder
            if let pane = appState.workspace.panes.values.first,
               let tabID = pane.activeTabID,
               let tab = appState.workspace.tabs[tabID],
               let session = appState.sessionManager.sessions[tab.contentID] {
                let terminalView = TerminalContainerView(session: session)
                addFullSubview(terminalView)
            } else {
                let placeholder = NSView()
                placeholder.wantsLayer = true
                placeholder.layer?.backgroundColor = NSColor.black.cgColor
                addFullSubview(placeholder)
            }
            return
        }

        let view = buildView(for: splitConfig)
        addFullSubview(view)
    }

    private func buildView(for node: SplitNode) -> NSView {
        switch node {
        case .leaf(let paneID):
            if let pane = appState.workspace.panes[paneID],
               let tabID = pane.activeTabID,
               let tab = appState.workspace.tabs[tabID],
               let session = appState.sessionManager.sessions[tab.contentID] {
                return TerminalContainerView(session: session)
            }
            let placeholder = NSView()
            placeholder.wantsLayer = true
            placeholder.layer?.backgroundColor = NSColor.black.cgColor
            return placeholder

        case .split(let direction, _, let first, let second):
            let splitView = NSSplitView()
            splitView.isVertical = (direction == .vertical)
            splitView.dividerStyle = .thin
            splitView.addArrangedSubview(buildView(for: first))
            splitView.addArrangedSubview(buildView(for: second))
            return splitView
        }
    }

    private func addFullSubview(_ view: NSView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor),
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
}

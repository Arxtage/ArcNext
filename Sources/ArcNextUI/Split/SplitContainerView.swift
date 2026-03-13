import AppKit
import ArcNextCore
import SwiftUI

/// Thin AppKit wrapper that hosts the reactive SwiftUI SplitContentView.
public final class SplitContainerView: NSView {
    private let appState: AppState

    public init(appState: AppState) {
        self.appState = appState
        super.init(frame: .zero)
        setupContent()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupContent() {
        let contentView = ContentAreaView(appState: appState)
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
}

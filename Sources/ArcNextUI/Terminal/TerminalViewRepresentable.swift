import AppKit
import ArcNextCore
import SwiftUI
import SwiftTerm

/// NSViewRepresentable that wraps TerminalContainerView for SwiftUI embedding.
/// Coordinator caches the view by pane ID to prevent recreation on state changes.
public struct TerminalViewRepresentable: NSViewRepresentable {
    let paneID: UUID
    let session: TerminalSession
    let appState: AppState
    let isActive: Bool

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public func makeNSView(context: Context) -> NSView {
        let wrapper = NSView(frame: .zero)
        wrapper.wantsLayer = true

        let terminalContainer = TerminalContainerView(session: session, appState: appState)
        terminalContainer.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(terminalContainer)

        NSLayoutConstraint.activate([
            terminalContainer.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 2),
            terminalContainer.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -2),
            terminalContainer.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 2),
            terminalContainer.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -2),
        ])

        context.coordinator.cachedView = wrapper
        context.coordinator.terminalContainer = terminalContainer
        updateBorder(wrapper: wrapper)
        return wrapper
    }

    public func updateNSView(_ nsView: NSView, context: Context) {
        updateBorder(wrapper: nsView)
    }

    private func updateBorder(wrapper: NSView) {
        wrapper.layer?.borderWidth = isActive ? 2 : 0
        wrapper.layer?.borderColor = isActive ? NSColor.controlAccentColor.cgColor : nil
        wrapper.layer?.cornerRadius = isActive ? 4 : 0
    }

    public final class Coordinator {
        var cachedView: NSView?
        var terminalContainer: TerminalContainerView?
    }
}

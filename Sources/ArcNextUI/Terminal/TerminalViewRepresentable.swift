import AppKit
import ArcNextCore
import SwiftUI
import SwiftTerm

/// NSViewRepresentable that wraps TerminalContainerView for SwiftUI embedding.
/// Coordinator caches the view by pane ID to prevent recreation on state changes.
public struct TerminalViewRepresentable: NSViewRepresentable {
    private static var containerCache: [UUID: TerminalContainerView] = [:]

    static func removeFromCache(sessionID: UUID) {
        containerCache.removeValue(forKey: sessionID)
    }

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

        let terminalContainer: TerminalContainerView
        if let cached = Self.containerCache[session.id] {
            cached.removeFromSuperview()
            terminalContainer = cached
        } else {
            terminalContainer = TerminalContainerView(paneID: paneID, session: session, appState: appState)
            Self.containerCache[session.id] = terminalContainer
        }

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
        context.coordinator.currentSessionID = session.id
        context.coordinator.wasActive = isActive
        context.coordinator.wasPaletteVisible = appState.isPaletteVisible
        updateBorder(wrapper: wrapper)
        return wrapper
    }

    public func updateNSView(_ nsView: NSView, context: Context) {
        // If the session changed (e.g. new tab selected), swap the terminal container
        if session.id != context.coordinator.currentSessionID {
            if let oldSessionID = context.coordinator.currentSessionID {
                // Keep the old container in cache (don't destroy it)
                context.coordinator.terminalContainer?.removeFromSuperview()
                // Only remove from cache if we're replacing the session entirely
                if Self.containerCache[oldSessionID] !== context.coordinator.terminalContainer {
                    Self.containerCache.removeValue(forKey: oldSessionID)
                }
            }

            let terminalContainer: TerminalContainerView
            if let cached = Self.containerCache[session.id] {
                cached.removeFromSuperview()
                terminalContainer = cached
            } else {
                terminalContainer = TerminalContainerView(paneID: paneID, session: session, appState: appState)
                Self.containerCache[session.id] = terminalContainer
            }

            terminalContainer.translatesAutoresizingMaskIntoConstraints = false
            nsView.addSubview(terminalContainer)

            NSLayoutConstraint.activate([
                terminalContainer.topAnchor.constraint(equalTo: nsView.topAnchor, constant: 2),
                terminalContainer.bottomAnchor.constraint(equalTo: nsView.bottomAnchor, constant: -2),
                terminalContainer.leadingAnchor.constraint(equalTo: nsView.leadingAnchor, constant: 2),
                terminalContainer.trailingAnchor.constraint(equalTo: nsView.trailingAnchor, constant: -2),
            ])

            context.coordinator.terminalContainer = terminalContainer
            context.coordinator.currentSessionID = session.id
        }

        updateBorder(wrapper: nsView)

        let wasActive = context.coordinator.wasActive
        let wasPaletteVisible = context.coordinator.wasPaletteVisible

        context.coordinator.wasActive = isActive
        context.coordinator.wasPaletteVisible = appState.isPaletteVisible

        if isActive && !appState.isPaletteVisible && (!wasActive || wasPaletteVisible) {
            context.coordinator.terminalContainer?.focusTerminal()
        }
    }

    private func updateBorder(wrapper: NSView) {
        wrapper.layer?.borderWidth = isActive ? 2 : 0
        wrapper.layer?.borderColor = isActive ? NSColor.controlAccentColor.cgColor : nil
        wrapper.layer?.cornerRadius = isActive ? 4 : 0
    }

    public final class Coordinator {
        var cachedView: NSView?
        var terminalContainer: TerminalContainerView?
        var currentSessionID: UUID?
        var wasActive = false
        var wasPaletteVisible = false
    }
}

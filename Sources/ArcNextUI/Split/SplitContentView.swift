import ArcNextCore
import SwiftUI

/// SwiftUI view that reactively renders the split tree from workspace.splitConfiguration.
/// Automatically re-renders when @Observable state changes.
public struct SplitContentView: View {
    let appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        Group {
            if let config = appState.workspace.splitConfiguration {
                nodeView(for: config)
            } else {
                placeholderView
            }
        }
    }

    // AnyView is needed here to break the recursive opaque return type.
    private func nodeView(for node: SplitNode) -> AnyView {
        switch node {
        case .leaf(let paneID):
            return AnyView(leafView(paneID: paneID))
        case .split(let direction, let ratio, let first, let second):
            return AnyView(
                GeometryReader { geo in
                    if direction == .vertical {
                        HStack(spacing: 1) {
                            nodeView(for: first)
                                .frame(width: geo.size.width * ratio)
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 1)
                            nodeView(for: second)
                        }
                    } else {
                        VStack(spacing: 1) {
                            nodeView(for: first)
                                .frame(height: geo.size.height * ratio)
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                            nodeView(for: second)
                        }
                    }
                }
            )
        }
    }

    @ViewBuilder
    private func leafView(paneID: UUID) -> some View {
        let isActive = appState.workspace.activePaneID == paneID
        if let pane = appState.workspace.panes[paneID],
           let tabID = pane.activeTabID,
           let tab = appState.workspace.tabs[tabID],
           let session = appState.sessionManager.sessions[tab.contentID] {
            TerminalViewRepresentable(
                paneID: paneID,
                session: session,
                appState: appState,
                isActive: isActive
            )
            .onTapGesture {
                appState.workspace.activePaneID = paneID
            }
        } else {
            placeholderView
                .onTapGesture {
                    appState.workspace.activePaneID = paneID
                }
        }
    }

    private var placeholderView: some View {
        Color.black
    }
}

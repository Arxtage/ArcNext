import ArcNextCore
import SwiftUI

public struct SidebarView: View {
    @Bindable var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Sidebar header
            HStack {
                Text("ArcNext")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: { appState.isPaletteVisible = true }) {
                    Image(systemName: "plus")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Tab list
            ScrollView {
                LazyVStack(spacing: 2) {
                    // Grouped tabs
                    ForEach(appState.workspace.tabGroups) { group in
                        SidebarGroupSection(
                            group: group,
                            tabs: group.tabIDs.compactMap { appState.workspace.tabs[$0] },
                            activeTabID: appState.workspace.activeTabID,
                            onSelectTab: { selectTab($0) },
                            onToggleCollapse: { appState.tidyService.toggleGroupCollapsed(group.id) }
                        )
                    }

                    // Ungrouped tabs
                    ForEach(appState.workspace.ungroupedTabIDs, id: \.self) { tabID in
                        if let tab = appState.workspace.tabs[tabID] {
                            SidebarTabRow(
                                tab: tab,
                                isActive: appState.workspace.activeTabID == tab.id,
                                onSelect: { selectTab(tab.id) },
                                onClose: { appState.tabManager.closeTab(tab.id) }
                            )
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
        .frame(maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }

    private func selectTab(_ tabID: UUID) {
        appState.tabManager.switchToTab(tabID)
    }
}

struct SidebarGroupSection: View {
    let group: TabGroup
    let tabs: [ArcNextCore.Tab]
    let activeTabID: UUID?
    let onSelectTab: (UUID) -> Void
    let onToggleCollapse: () -> Void

    var body: some View {
        VStack(spacing: 2) {
            // Group header
            Button(action: onToggleCollapse) {
                HStack(spacing: 6) {
                    Image(systemName: group.isCollapsed ? "chevron.right" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Circle()
                        .fill(group.color.swiftUIColor)
                        .frame(width: 8, height: 8)
                    Text(group.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(tabs.count)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 4)
            }
            .buttonStyle(.plain)

            if !group.isCollapsed {
                ForEach(tabs) { tab in
                    SidebarTabRow(
                        tab: tab,
                        isActive: activeTabID == tab.id,
                        onSelect: { onSelectTab(tab.id) },
                        onClose: {}
                    )
                    .padding(.leading, 16)
                }
            }
        }
    }
}

struct SidebarTabRow: View {
    let tab: ArcNextCore.Tab
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: tab.contentType == .terminal ? "terminal" : "globe")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(tab.title)
                .font(.subheadline)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            if tab.isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            if isHovering {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? Color.accentColor.opacity(0.2) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { isHovering = $0 }
    }
}

extension GroupColor {
    var swiftUIColor: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .gray: return .gray
        }
    }
}

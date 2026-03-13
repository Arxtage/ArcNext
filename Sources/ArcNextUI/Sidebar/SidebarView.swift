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
                    ForEach(sidebarUngroupedEntries) { entry in
                        ungroupedEntryView(entry)
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

    private var sidebarUngroupedEntries: [SidebarUngroupedEntry] {
        let combinedTabIDs = appState.workspace.visibleUngroupedSplitTabIDs
        guard combinedTabIDs.count > 1 else {
            return appState.workspace.ungroupedTabIDs.map { SidebarUngroupedEntry(kind: .single($0)) }
        }

        let combinedSet = Set(combinedTabIDs)
        var insertedCombinedRow = false

        return appState.workspace.ungroupedTabIDs.compactMap { tabID in
            if combinedSet.contains(tabID) {
                guard !insertedCombinedRow else { return nil }
                insertedCombinedRow = true
                return SidebarUngroupedEntry(kind: .combined(combinedTabIDs))
            }

            return SidebarUngroupedEntry(kind: .single(tabID))
        }
    }

    @ViewBuilder
    private func ungroupedEntryView(_ entry: SidebarUngroupedEntry) -> some View {
        switch entry.kind {
        case .combined(let tabIDs):
            let tabs = tabIDs.compactMap { appState.workspace.tabs[$0] }
            if tabs.count > 1 {
                CompactTabRow(
                    tabs: tabs,
                    activeTabID: appState.workspace.activeTabID,
                    onSelectTab: selectTab
                )
            }
        case .single(let tabID):
            if let tab = appState.workspace.tabs[tabID] {
                SidebarTabRow(
                    tab: tab,
                    isActive: appState.workspace.activeTabID == tab.id,
                    onSelect: { selectTab(tab.id) },
                    onClose: { appState.closeTab(tab.id) }
                )
            }
        }
    }
}

private struct SidebarUngroupedEntry: Identifiable {
    enum Kind {
        case combined([UUID])
        case single(UUID)
    }

    let kind: Kind

    var id: String {
        switch kind {
        case .combined(let tabIDs):
            return "combined:" + tabIDs.map(\.uuidString).joined(separator: ",")
        case .single(let tabID):
            return tabID.uuidString
        }
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
            } else if !tabs.isEmpty {
                CompactTabRow(
                    tabs: tabs,
                    activeTabID: activeTabID,
                    onSelectTab: onSelectTab
                )
                .padding(.leading, 16)
            }
        }
    }
}

struct CompactTabRow: View {
    let tabs: [ArcNextCore.Tab]
    let activeTabID: UUID?
    let onSelectTab: (UUID) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(tabs.enumerated()), id: \.element.id) { index, tab in
                    let isActive = activeTabID == tab.id

                    Button { onSelectTab(tab.id) } label: {
                        HStack(spacing: 4) {
                            Image(systemName: tab.contentType == .terminal ? "terminal" : "globe")
                                .font(.system(size: 10))
                                .foregroundStyle(isActive ? .primary : .secondary)
                            Text(tab.title)
                                .font(.system(size: 11))
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: 48)
                                .foregroundStyle(isActive ? .primary : .secondary)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isActive ? Color.accentColor.opacity(0.2) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)

                    if index < tabs.count - 1 {
                        Divider()
                            .frame(height: 14)
                            .padding(.horizontal, 2)
                    }
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.06))
        )
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

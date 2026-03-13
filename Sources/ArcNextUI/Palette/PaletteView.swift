import ArcNextCore
import SwiftUI

/// Universal Cmd+T palette — open folders, switch tabs, reopen closed tabs, jump to groups, run actions.
public struct PaletteView: View {
    @Bindable var appState: AppState
    @State private var searchText = ""
    @State private var selectedIndex = 0
    @FocusState private var isSearchFocused: Bool

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search tabs, folders, actions...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .focused($isSearchFocused)
                    .onSubmit { executeSelectedItem() }
            }
            .padding(12)

            Divider()

            // Results list
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                        PaletteItemRow(
                            item: item,
                            isSelected: index == selectedIndex
                        )
                        .onTapGesture { executeItem(item) }
                    }
                }
                .padding(8)
            }
            .frame(maxHeight: 400)
        }
        .frame(width: 600)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 20)
        .onAppear { isSearchFocused = true }
        .onChange(of: searchText) { _, _ in selectedIndex = 0 }
        .onKeyPress(.upArrow) {
            selectedIndex = max(0, selectedIndex - 1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            selectedIndex = min(filteredItems.count - 1, selectedIndex + 1)
            return .handled
        }
        .onKeyPress(.escape) {
            appState.isPaletteVisible = false
            return .handled
        }
    }

    private var filteredItems: [PaletteItem] {
        var items: [PaletteItem] = []

        // Open tabs
        for tab in appState.workspace.tabs.values {
            items.append(PaletteItem(
                id: tab.id,
                title: tab.title,
                subtitle: "Open tab",
                icon: "terminal",
                kind: .switchTab(tab.id)
            ))
        }

        // Recently closed
        for tab in appState.tabManager.recentlyClosed.prefix(5) {
            items.append(PaletteItem(
                id: UUID(),
                title: tab.title,
                subtitle: "Recently closed",
                icon: "arrow.counterclockwise",
                kind: .reopenTab
            ))
        }

        // Recent directories
        for dir in appState.directoryTracker.recentDirectories.prefix(10) {
            items.append(PaletteItem(
                id: UUID(),
                title: dir.lastPathComponent,
                subtitle: dir.path,
                icon: "folder",
                kind: .openDirectory(dir)
            ))
        }

        // Actions
        items.append(PaletteItem(
            id: UUID(),
            title: "New Terminal",
            subtitle: "Open a new terminal tab",
            icon: "plus.rectangle",
            kind: .newTerminal
        ))
        items.append(PaletteItem(
            id: UUID(),
            title: "Split Vertical",
            subtitle: "Split current pane vertically",
            icon: "rectangle.split.1x2",
            kind: .splitVertical
        ))
        items.append(PaletteItem(
            id: UUID(),
            title: "Split Horizontal",
            subtitle: "Split current pane horizontally",
            icon: "rectangle.split.2x1",
            kind: .splitHorizontal
        ))

        if searchText.isEmpty { return items }

        let query = searchText.lowercased()
        return items.filter {
            $0.title.lowercased().contains(query) ||
            $0.subtitle.lowercased().contains(query)
        }
    }

    private func executeSelectedItem() {
        guard selectedIndex < filteredItems.count else { return }
        executeItem(filteredItems[selectedIndex])
    }

    private func executeItem(_ item: PaletteItem) {
        appState.isPaletteVisible = false
        appState.executePaletteAction(item.kind)
    }
}

public struct PaletteItem: Identifiable {
    public let id: UUID
    public let title: String
    public let subtitle: String
    public let icon: String
    public let kind: PaletteActionKind
}

struct PaletteItemRow: View {
    let item: PaletteItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.icon)
                .frame(width: 20)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .font(.body)
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        )
        .contentShape(Rectangle())
    }
}

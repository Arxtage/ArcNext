import ArcNextCore
import SwiftUI

/// Main content area: split view + palette overlay.
public struct ContentAreaView: View {
    @Bindable var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        ZStack {
            SplitContentView(appState: appState)

            if appState.isPaletteVisible {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        appState.isPaletteVisible = false
                    }
                    .transition(.opacity)

                PaletteView(appState: appState)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.easeInOut(duration: 0.15), value: appState.isPaletteVisible)
    }
}

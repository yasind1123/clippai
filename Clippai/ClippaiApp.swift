import AppKit
import SwiftUI

@main
struct ClippaiApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent()
                .environmentObject(viewModel)
        } label: {
            Image("MenuBarIcon")
                .renderingMode(.original)
                .accessibilityLabel("Clippai")
        }
        WindowGroup("Clippai", id: "main") {
            MainWindowView()
                .environmentObject(viewModel)
        }
    }
}

private struct MenuBarContent: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button("Open Clippai") {
                openWindow(id: "main")
            }
            Button("Quick Paste") {
                viewModel.showQuickPastePanel()
            }
            Button("Clear All") {
                viewModel.clearAllHistory()
            }
            Divider()
            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
        .padding(8)
    }
}

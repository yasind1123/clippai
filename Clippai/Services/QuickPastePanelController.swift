import AppKit
import SwiftUI

@MainActor
final class QuickPastePanelController {
    static let windowIdentifier = NSUserInterfaceItemIdentifier("quickPastePanel")

    private weak var viewModel: AppViewModel?
    private var panel: NSPanel?

    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }

    func show() {
        if panel == nil {
            panel = buildPanel()
        }

        if let panel {
            position(panel: panel)
        }
        viewModel?.selectFirstIfNeeded()
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func close() {
        panel?.orderOut(nil)
    }

    private func buildPanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 420),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isReleasedWhenClosed = false
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.hidesOnDeactivate = true
        panel.identifier = Self.windowIdentifier

        if let viewModel {
            let rootView = QuickPastePanelView()
                .environmentObject(viewModel)
            panel.contentView = NSHostingView(rootView: rootView)
        }

        return panel
    }

    private func position(panel: NSPanel) {
        guard let screen = targetScreen() else {
            panel.center()
            return
        }
        let visible = screen.visibleFrame
        let size = panel.frame.size
        let x = visible.midX - size.width / 2
        let y = visible.maxY - size.height - 80
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func targetScreen() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { screen in
            NSMouseInRect(mouseLocation, screen.frame, false)
        } ?? NSScreen.main
    }
}

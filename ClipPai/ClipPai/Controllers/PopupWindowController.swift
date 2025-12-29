import AppKit
import SwiftUI

class PopupWindowController {
    private var panel: NSPanel?
    private var store: ClipboardStore
    var onSelect: ((ClipboardItem) -> Void)?
    
    init(store: ClipboardStore) {
        self.store = store
    }
    
    func show() {
        if let existingPanel = panel {
            // Check if already visible, maybe just bring to front
            if existingPanel.isVisible {
                existingPanel.makeKeyAndOrderFront(nil)
                return
            }
            existingPanel.close()
        }
        
        let contentView = ClipboardPopupView(
            store: store,
            onSelect: { [weak self] item in
                self?.hide()
                self?.onSelect?(item)
            },
            onCancel: { [weak self] in
                self?.hide()
            }
        )
        
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        panel.contentView = NSHostingView(rootView: contentView)
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.backgroundColor = .clear
        panel.hasShadow = true
        
        // Position near mouse cursor
        let mouseLocation = NSEvent.mouseLocation
        // We want to center it somewhat under the cursor or near it
        let screenHeight = NSScreen.main?.frame.height ?? 1080
        
        // Coordinates in AppKit are bottom-left origin.
        // NSEvent.mouseLocation returns bottom-left origin coordinates.
        
        let x = mouseLocation.x - 200 // Center horizontally
        let y = mouseLocation.y - 500 // Position below cursor (height is 500)
        
        panel.setFrameOrigin(NSPoint(x: x, y: y))
        
        // Essential for receiving key events
        panel.makeKeyAndOrderFront(nil)
        
        self.panel = panel
    }
    
    func hide() {
        panel?.close()
        panel = nil
    }
}

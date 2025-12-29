import SwiftUI
import AppKit

@main
struct ClipPaiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Menu bar app doesn't need a WindowGroup
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let clipboardMonitor = ClipboardMonitor()
    private let clipboardStore = ClipboardStore()
    private let hotkeyManager = HotkeyManager()
    private var popupController: PopupWindowController!
    private let pasteService = PasteService()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupClipboardMonitor()
        setupPopup()
        setupHotkey() // Starts hotkey listener
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "ClipPai")
        }
        
        let menu = NSMenu()
        // Menu item to manually show history
        let showItem = NSMenuItem(title: "Show History (⌘⇧V)", action: #selector(showPopup), keyEquivalent: "V")
        showItem.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(showItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }
    
    private func setupClipboardMonitor() {
        clipboardMonitor.onNewItem = { [weak self] item in
            self?.clipboardStore.add(item)
        }
        clipboardMonitor.start()
    }
    
    private func setupPopup() {
        popupController = PopupWindowController(store: clipboardStore)
        popupController.onSelect = { [weak self] item in
            self?.pasteService.paste(item)
        }
    }
    
    private func setupHotkey() {
        hotkeyManager.onHotkey = { [weak self] in
            self?.showPopup()
        }
        hotkeyManager.start()
    }
    
    @objc private func showPopup() {
        // Bring app to front to ensure processing
        NSApp.activate(ignoringOtherApps: true)
        popupController.show()
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

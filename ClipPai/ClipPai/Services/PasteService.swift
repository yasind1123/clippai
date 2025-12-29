import AppKit

class PasteService {
    func paste(_ item: ClipboardItem) {
        // 1. Put the selected item onto the clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch item.type {
        case .text(let text):
            pasteboard.setString(text, forType: .string)
        case .image(let image):
            if let tiffData = image.tiffRepresentation {
                pasteboard.setData(tiffData, forType: .tiff)
            }
        }
        
        // 2. Simulate Command + V to paste into the active application
        // We need a slight delay to ensure the clipboard is updated and system focus is restored
        // if this is called from a window that steals focus.
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.simulatePaste()
        }
    }
    
    private func simulatePaste() {
        // Source state ID .hidSystemState means we are injecting into the system event stream
        let source = CGEventSource(stateID: .hidSystemState)
        
        // V key is 0x09
        let keyCode: CGKeyCode = 0x09
        
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        keyDown?.flags = .maskCommand
        
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        keyUp?.flags = .maskCommand
        
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}

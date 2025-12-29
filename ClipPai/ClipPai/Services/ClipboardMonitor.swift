import AppKit
import Combine

class ClipboardMonitor: ObservableObject {
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    
    var onNewItem: ((ClipboardItem) -> Void)?
    
    func start() {
        lastChangeCount = NSPasteboard.general.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        
        // Text check
        if let text = pasteboard.string(forType: .string) {
            // Avoid capturing empty strings or whitespace only if desired, keeping simple for now
            if !text.isEmpty {
                let item = ClipboardItem(type: .text(text))
                onNewItem?(item)
                return
            }
        }
        
        // Image check
        // .tiff is often the primary type for images in NSPasteboard
        if let imageData = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png),
           let image = NSImage(data: imageData) {
            let item = ClipboardItem(type: .image(image))
            onNewItem?(item)
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
}

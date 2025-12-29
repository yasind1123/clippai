import Foundation
import Combine

class ClipboardStore: ObservableObject {
    @Published var items: [ClipboardItem] = []
    private let maxItems = 50
    
    func add(_ item: ClipboardItem) {
        // Prevent duplicates at the top of the list
        if let lastItem = items.first {
            if isSame(lastItem, item) { return }
        }
        
        items.insert(item, at: 0)
        
        if items.count > maxItems {
            items.removeLast()
        }
    }
    
    private func isSame(_ a: ClipboardItem, _ b: ClipboardItem) -> Bool {
        switch (a.type, b.type) {
        case (.text(let t1), .text(let t2)):
            return t1 == t2
        case (.image, .image):
            // Image comparison is expensive and tricky, for now assume different
            // or we could compare data size/hash if needed.
            return false
        default:
            return false
        }
    }
}

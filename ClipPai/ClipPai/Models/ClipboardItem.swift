import AppKit

enum ClipboardItemType {
    case text(String)
    case image(NSImage)
}

struct ClipboardItem: Identifiable {
    let id = UUID()
    let type: ClipboardItemType
    let timestamp = Date()
    
    var preview: String {
        switch type {
        case .text(let str):
            let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
            return String(trimmed.prefix(100))
        case .image:
            return "[Image]"
        }
    }
}

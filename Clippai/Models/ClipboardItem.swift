import Foundation

struct ClipboardItem: Identifiable, Codable, Equatable {
    enum ContentType: String, Codable {
        case text
        case image
    }

    let id: UUID
    let createdAt: Date
    let type: ContentType
    let text: String?
    let imagePath: String?
    let sourceAppBundleId: String?
    let sourceAppName: String?
    let hash: String

    func matches(query: String) -> Bool {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return true }
        if let text {
            return text.lowercased().contains(needle)
        }
        return type == .image && needle == "image"
    }
}

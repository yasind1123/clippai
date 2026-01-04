import AppKit

@MainActor
final class ClipboardStore: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []

    private let maxItems: Int
    private let fileManager = FileManager.default
    private let baseURL: URL
    private let itemsURL: URL
    private let imagesURL: URL

    init(maxItems: Int = 200) {
        self.maxItems = maxItems

        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")

        baseURL = appSupport.appendingPathComponent("clippai", isDirectory: true)
        itemsURL = baseURL.appendingPathComponent("items.json")
        imagesURL = baseURL.appendingPathComponent("images", isDirectory: true)

        createDirectoriesIfNeeded()
        load()
    }

    func add(capture: ClipboardCapture) {
        let duplicates = items.enumerated().filter { entry in
            entry.element.hash == capture.hash && entry.element.type == capture.type
        }

        let existingItem = duplicates.first?.element
        if !duplicates.isEmpty {
            for entry in duplicates.sorted(by: { $0.offset > $1.offset }) {
                items.remove(at: entry.offset)
            }
        }

        var imagePath: String?
        if capture.type == .image {
            if let existingItem, let existingPath = existingItem.imagePath {
                imagePath = existingPath
            } else if let image = capture.image {
                imagePath = storeImage(image, hash: capture.hash)
            }
        }

        let item = ClipboardItem(
            id: existingItem?.id ?? UUID(),
            createdAt: Date(),
            type: capture.type,
            text: capture.text,
            imagePath: imagePath ?? existingItem?.imagePath,
            sourceAppBundleId: capture.sourceAppBundleId ?? existingItem?.sourceAppBundleId,
            sourceAppName: capture.sourceAppName ?? existingItem?.sourceAppName,
            hash: capture.hash
        )

        items.insert(item, at: 0)
        trimIfNeeded()
        save()
    }

    func removeItems(at offsets: IndexSet) {
        let removed = offsets.map { items[$0] }
        for offset in offsets.sorted(by: >) {
            items.remove(at: offset)
        }
        removed.forEach { cleanup(item: $0) }
        save()
    }

    func clearAll() {
        let removed = items
        items.removeAll()
        removed.forEach { cleanup(item: $0) }
        save()
    }

    func item(for id: UUID?) -> ClipboardItem? {
        guard let id else { return nil }
        return items.first { $0.id == id }
    }

    private func createDirectoriesIfNeeded() {
        try? fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true, attributes: nil)
        try? fileManager.createDirectory(at: imagesURL, withIntermediateDirectories: true, attributes: nil)
    }

    private func storeImage(_ image: NSImage, hash: String) -> String? {
        let fileURL = imagesURL.appendingPathComponent("\(hash).png")
        if fileManager.fileExists(atPath: fileURL.path) {
            return fileURL.path
        }
        guard let data = ClipboardImageEncoder.pngData(from: image) else { return nil }
        do {
            try data.write(to: fileURL, options: .atomic)
            return fileURL.path
        } catch {
            return nil
        }
    }

    private func trimIfNeeded() {
        guard items.count > maxItems else { return }
        let overflow = items.count - maxItems
        let removed = items.suffix(overflow)
        items.removeLast(overflow)
        removed.forEach { cleanup(item: $0) }
    }

    private func cleanup(item: ClipboardItem) {
        guard item.type == .image, let path = item.imagePath else { return }
        try? fileManager.removeItem(atPath: path)
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: itemsURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: itemsURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let stored = try? decoder.decode([ClipboardItem].self, from: data) else { return }
        items = stored
        let originalCount = items.count
        dedupeInPlace()
        if items.count != originalCount {
            save()
        }
    }

    private func dedupeInPlace() {
        var seen = Set<String>()
        items = items.filter { item in
            let key = "\(item.type.rawValue)|\(item.hash)"
            if seen.contains(key) {
                return false
            }
            seen.insert(key)
            return true
        }
    }
}

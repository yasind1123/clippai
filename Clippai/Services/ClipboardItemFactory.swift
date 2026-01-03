import AppKit

enum ClipboardItemFactory {
    static func capture(from pasteboard: NSPasteboard) -> ClipboardCapture? {
        let frontmostApp = NSWorkspace.shared.frontmostApplication
        let sourceBundleId = frontmostApp?.bundleIdentifier
        let sourceName = frontmostApp?.localizedName

        if let string = pasteboard.string(forType: .string) {
            let hash = ClipboardHasher.sha256(Data(string.utf8))
            return ClipboardCapture(
                type: .text,
                text: string,
                image: nil,
                hash: hash,
                sourceAppBundleId: sourceBundleId,
                sourceAppName: sourceName
            )
        }

        if let rtfData = pasteboard.data(forType: .rtf),
           let attributed = try? NSAttributedString(data: rtfData, options: [:], documentAttributes: nil) {
            let string = attributed.string
            let hash = ClipboardHasher.sha256(Data(string.utf8))
            return ClipboardCapture(
                type: .text,
                text: string,
                image: nil,
                hash: hash,
                sourceAppBundleId: sourceBundleId,
                sourceAppName: sourceName
            )
        }

        if let image = NSImage(pasteboard: pasteboard) {
            let data = ClipboardImageEncoder.pngData(from: image) ?? image.tiffRepresentation ?? Data()
            let hash = ClipboardHasher.sha256(data)
            return ClipboardCapture(
                type: .image,
                text: nil,
                image: image,
                hash: hash,
                sourceAppBundleId: sourceBundleId,
                sourceAppName: sourceName
            )
        }

        return nil
    }
}

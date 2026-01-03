import AppKit

struct ClipboardCapture {
    let type: ClipboardItem.ContentType
    let text: String?
    let image: NSImage?
    let hash: String
    let sourceAppBundleId: String?
    let sourceAppName: String?
}

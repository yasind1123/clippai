import AppKit

final class ClipboardMonitor {
    var onCapture: ((ClipboardCapture) -> Void)?

    private var timer: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount

    func start(pollInterval: TimeInterval = 0.5) {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkPasteboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        guard let capture = ClipboardItemFactory.capture(from: pasteboard) else { return }
        onCapture?(capture)
    }

    deinit {
        stop()
    }
}

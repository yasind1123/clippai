import AppKit
import Combine
import Foundation

@MainActor
final class AppViewModel: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []
    @Published var query: String = ""
    @Published var selectedItemId: UUID?

    private let store: ClipboardStore
    private let monitor: ClipboardMonitor
    private let hotkeyManager: HotkeyManager
    private let pasteController: PasteController
    private lazy var quickPastePanel = QuickPastePanelController(viewModel: self)
    private var previousApp: NSRunningApplication?
    private var cancellables = Set<AnyCancellable>()

    init() {
        store = ClipboardStore()
        monitor = ClipboardMonitor()
        hotkeyManager = HotkeyManager()
        pasteController = PasteController()

        store.$items
            .receive(on: RunLoop.main)
            .sink { [weak self] items in
                self?.items = items
            }
            .store(in: &cancellables)

        monitor.onCapture = { [weak self] capture in
            guard let self else { return }
            Task { @MainActor in
                self.store.add(capture: capture)
            }
        }
        monitor.start()

        hotkeyManager.registerDefault { [weak self] in
            Task { @MainActor in
                self?.showQuickPastePanel()
            }
        }
    }

    var filteredItems: [ClipboardItem] {
        guard !query.isEmpty else { return items }
        return items.filter { $0.matches(query: query) }
    }

    var selectedItem: ClipboardItem? {
        store.item(for: selectedItemId)
    }

    func showQuickPastePanel() {
        previousApp = NSWorkspace.shared.frontmostApplication
        quickPastePanel.show()
    }

    func removeItems(at offsets: IndexSet) {
        store.removeItems(at: offsets)
    }

    func clearAllHistory() {
        store.clearAll()
        selectedItemId = nil
    }

    func selectFirstIfNeeded() {
        guard selectedItemId == nil else { return }
        selectedItemId = filteredItems.first?.id
    }

    func pasteSelectedItem() {
        guard let item = store.item(for: selectedItemId) else { return }
        quickPastePanel.close()
        let target = previousApp
        previousApp = nil
        pasteController.paste(item: item, targetApp: target)
    }
}

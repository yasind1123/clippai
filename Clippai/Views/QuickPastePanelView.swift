import AppKit
import SwiftUI

struct QuickPastePanelView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var isVisible = false
    @State private var keyMonitor: Any?
    @FocusState private var isListFocused: Bool

    private let maxItems = 20

    var body: some View {
        ZStack {
            LiquidBackdrop()

            VStack(spacing: 12) {
                GlassSearchField(placeholder: "Filter clipboard", text: $viewModel.query)

                GlassPanel(cornerRadius: 18, padding: 0) {
                    List(selection: $viewModel.selectedItemId) {
                        ForEach(displayedItems) { item in
                            let isSelected = viewModel.selectedItemId == item.id
                            QuickPasteRowView(item: item, isSelected: isSelected)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.selectedItemId = item.id
                                    viewModel.pasteSelectedItem()
                                }
                                .tag(item.id)
                                .listRowInsets(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                    .focusable()
                    .focused($isListFocused)
                    .background(ListSelectionConfigurator())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 18)
        }
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.98)
        .animation(.easeOut(duration: 0.25), value: isVisible)
        .frame(minWidth: 520, minHeight: 420)
        .onAppear {
            DispatchQueue.main.async {
                viewModel.selectFirstIfNeeded()
                isListFocused = true
            }
            isVisible = true
            installKeyMonitor()
        }
        .onDisappear {
            removeKeyMonitor()
        }
    }

    private var displayedItems: [ClipboardItem] {
        Array(viewModel.filteredItems.prefix(maxItems))
    }

    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard NSApp.keyWindow?.identifier == QuickPastePanelController.windowIdentifier else {
                return event
            }
            return handleKey(event)
        }
    }

    private func removeKeyMonitor() {
        guard let keyMonitor else { return }
        NSEvent.removeMonitor(keyMonitor)
        self.keyMonitor = nil
    }

    private func handleKey(_ event: NSEvent) -> NSEvent? {
        switch event.keyCode {
        case 36, 76:
            if viewModel.selectedItemId == nil {
                viewModel.selectedItemId = displayedItems.first?.id
            }
            viewModel.pasteSelectedItem()
            return nil
        case 53:
            NSApp.keyWindow?.close()
            return nil
        default:
            return event
        }
    }
}

private struct QuickPasteRowView: View {
    let item: ClipboardItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            previewIcon

            VStack(alignment: .leading, spacing: 4) {
                Text(primaryText)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                Text(secondaryText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(item.createdAt, style: .time)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(10)
        .background(GlassRowBackground(isSelected: isSelected))
    }

    private var previewIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )

            if item.type == .image, let path = item.imagePath, let image = NSImage(contentsOfFile: path) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(4)
            } else {
                Image(systemName: item.type == .text ? "doc.plaintext" : "photo")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
        .frame(width: 40, height: 40)
    }

    private var primaryText: String {
        switch item.type {
        case .text:
            return item.text?.replacingOccurrences(of: "\n", with: " ") ?? ""
        case .image:
            return "Image"
        }
    }

    private var secondaryText: String {
        AppNameResolver.displayName(
            sourceName: item.sourceAppName,
            bundleId: item.sourceAppBundleId
        ) ?? "Unknown app"
    }
}

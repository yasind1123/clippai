import AppKit
import SwiftUI

struct MainWindowView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var isVisible = false

    var body: some View {
        ZStack {
            LiquidBackdrop()

            NavigationSplitView {
                VStack(spacing: 12) {
                    GlassSearchField(placeholder: "Search history", text: $viewModel.query)

                    GlassPanel(cornerRadius: 18, padding: 0) {
                        List(selection: $viewModel.selectedItemId) {
                            ForEach(viewModel.filteredItems) { item in
                                let isSelected = viewModel.selectedItemId == item.id
                                ClipboardRowView(item: item, isSelected: isSelected)
                                    .tag(item.id)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            }
                            .onDelete(perform: viewModel.removeItems)
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.plain)
                        .background(ListSelectionConfigurator())
                    }
                }
                .padding(16)
            } detail: {
                GlassPanel(cornerRadius: 22, padding: 0) {
                    ClipboardDetailView(item: viewModel.selectedItem)
                        .padding(16)
                }
                .padding(16)
            }
            .navigationSplitViewStyle(.balanced)
        }
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.99)
        .animation(.easeOut(duration: 0.25), value: isVisible)
        .frame(minWidth: 980, minHeight: 640)
        .onAppear {
            isVisible = true
        }
    }

}

private struct ClipboardRowView: View {
    let item: ClipboardItem
    let isSelected: Bool
    private var layoutScale: CGFloat { isSelected ? 1.32 : 1 }

    var body: some View {
        HStack(spacing: scaled(12)) {
            thumbnail

            VStack(alignment: .leading, spacing: scaled(6)) {
                Text(item.type == .text ? "Text" : "Image")
                    .font(.system(size: scaled(13), weight: .semibold, design: .rounded))
                Text(itemPreview)
                    .font(.system(size: scaled(13), weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: scaled(4)) {
                Text(item.createdAt, style: .time)
                    .font(.system(size: scaled(11), weight: .regular, design: .rounded))
                Text(item.createdAt, style: .relative)
                    .font(.system(size: scaled(11), weight: .regular, design: .rounded))
            }
            .foregroundColor(.secondary)
        }
        .padding(scaled(12))
        .background(GlassRowBackground(isSelected: isSelected))
    }

    private var thumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: scaled(10), style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: scaled(10), style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )

            if item.type == .image, let path = item.imagePath, let image = NSImage(contentsOfFile: path) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: scaled(8), style: .continuous))
                    .padding(scaled(4))
            } else {
                Image(systemName: item.type == .text ? "doc.plaintext" : "photo")
                    .font(.system(size: scaled(18), weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
        .frame(width: scaled(44), height: scaled(44))
    }

    private var itemPreview: String {
        switch item.type {
        case .text:
            return item.text?.replacingOccurrences(of: "\n", with: " ") ?? ""
        case .image:
            return AppNameResolver.displayName(
                sourceName: item.sourceAppName,
                bundleId: item.sourceAppBundleId
            ) ?? "Image capture"
        }
    }

    private func scaled(_ value: CGFloat) -> CGFloat {
        value * layoutScale
    }
}

private struct ClipboardDetailView: View {
    let item: ClipboardItem?

    var body: some View {
        Group {
            if let item {
                switch item.type {
                case .text:
                    ScrollView {
                        Text(item.text ?? "")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                    }
                case .image:
                    if let path = item.imagePath, let image = NSImage(contentsOfFile: path) {
                        ScrollView([.horizontal, .vertical]) {
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(16)
                        }
                    } else {
                        emptyState(text: "Image not available")
                    }
                }
            } else {
                emptyState(text: "Select an item from the list")
            }
        }
    }

    private func emptyState(text: String) -> some View {
        VStack(spacing: 12) {
            GlassIcon(systemName: "cursorarrow.click")
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

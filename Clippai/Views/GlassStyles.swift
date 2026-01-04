import AppKit
import SwiftUI

struct LiquidBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor).opacity(0.92),
                    Color(nsColor: .controlBackgroundColor).opacity(0.9),
                    Color.accentColor.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.accentColor.opacity(0.32))
                .blur(radius: 140)
                .offset(x: -160, y: -140)
                .blendMode(.screen)

            Circle()
                .fill(Color.cyan.opacity(0.28))
                .blur(radius: 160)
                .offset(x: 180, y: 140)
                .blendMode(.screen)

            Circle()
                .fill(Color.white.opacity(0.18))
                .blur(radius: 200)
                .offset(x: 40, y: -220)
                .blendMode(.screen)

            RoundedRectangle(cornerRadius: 240, style: .continuous)
                .fill(Color.white.opacity(0.16))
                .blur(radius: 160)
                .rotationEffect(.degrees(12))
                .offset(x: -200, y: 160)
                .blendMode(.screen)
        }
        .ignoresSafeArea()
    }
}

struct GlassSurface: View {
    let cornerRadius: CGFloat
    let highlightOpacity: Double

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        shape
            .fill(.ultraThinMaterial)
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.45),
                        Color.white.opacity(0.08),
                        Color.white.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(shape)
                .blendMode(.screen)
            )
            .overlay(
                shape.stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.85),
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.55)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            )
            .overlay(shape.fill(Color.white.opacity(highlightOpacity)).blendMode(.softLight))
    }
}

struct GlassPanel<Content: View>: View {
    let cornerRadius: CGFloat
    let padding: CGFloat
    let content: Content

    init(cornerRadius: CGFloat = 16, padding: CGFloat = 12, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(GlassSurface(cornerRadius: cornerRadius, highlightOpacity: 0.12))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct GlassRowBackground: View {
    let isSelected: Bool

    var body: some View {
        if isSelected {
            Color.clear
        } else {
            GlassSurface(cornerRadius: 12, highlightOpacity: 0.1)
                .shadow(
                    color: Color.black.opacity(0.14),
                    radius: 8,
                    x: 0,
                    y: 5
                )
        }
    }
}

struct GlassIcon: View {
    let systemName: String

    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Circle().stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.7),
                                Color.white.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                )
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
        }
        .frame(width: 36, height: 36)
    }
}

struct GlassSearchField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
        }
        .padding(10)
        .background(GlassSurface(cornerRadius: 12, highlightOpacity: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct ListSelectionConfigurator: NSViewRepresentable {
    var highlightStyle: NSTableView.SelectionHighlightStyle = .none
    var focusRingType: NSFocusRingType = .none

    func makeNSView(context: Context) -> NSView {
        NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let tableView = nsView.enclosingTableView() else { return }
            tableView.selectionHighlightStyle = highlightStyle
            tableView.focusRingType = focusRingType
            tableView.backgroundColor = .clear
        }
    }
}

private extension NSView {
    func enclosingTableView() -> NSTableView? {
        var view: NSView? = self
        while let current = view {
            if let tableView = current as? NSTableView {
                return tableView
            }
            if let scrollView = current as? NSScrollView,
               let tableView = scrollView.documentView as? NSTableView {
                return tableView
            }
            view = current.superview
        }
        return nil
    }
}

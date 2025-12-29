import SwiftUI
import Carbon

// Helper for VisualEffect
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

struct ClipboardPopupView: View {
    @ObservedObject var store: ClipboardStore
    var onSelect: (ClipboardItem) -> Void
    var onCancel: () -> Void
    
    // We'll manage selection state here.
    // For a robust keyboard navigation, usually we need to handle events at the window level or use FocusState.
    // However, since this is a simple popup, handling key events on the view with a hidden input or NSEvent monitoring might be needed.
    // SwiftUI's .onKeyPress is available on newer macOS versions. Assuming macOS 14+ or using a custom handler.
    // To support slightly older macOS, we might rely on the parent window controller forwarding key events or using a hidden button.
    
    // For simplicity, let's assume we receive key events or use a simple list.
    // Actually, SwiftUI List supports selection.
    
    @State private var selectionId: UUID?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Clipboard History")
                    .font(.headline)
                Spacer()
                Text("⌘⇧V")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            if store.items.isEmpty {
                VStack {
                    Spacer()
                    Text("No clips found")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(store.items) { item in
                                ClipboardItemRow(item: item, isSelected: selectionId == item.id)
                                    .id(item.id)
                                    .onTapGesture {
                                        onSelect(item)
                                    }
                            }
                        }
                    }
                    .onChange(of: selectionId) { newValue in
                        if let id = newValue {
                            withAnimation {
                                proxy.scrollTo(id, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
        .frame(width: 400, height: 500)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)) // Translucent background
        .cornerRadius(12)
        .overlay(
            // Invisible view to capture key events if focused
            KeyboardHandler(onKeyDown: handleKeyDown)
                .frame(width: 0, height: 0)
        )
    }
    
    private func handleKeyDown(_ event: NSEvent) {
        if event.keyCode == 53 { // ESC
            onCancel()
            return
        }
        
        if event.keyCode == 36 { // Return
            if let id = selectionId, let item = store.items.first(where: { $0.id == id }) {
                onSelect(item)
            }
            return
        }
        
        if event.keyCode == 126 { // Up Arrow
            moveSelection(-1)
        } else if event.keyCode == 125 { // Down Arrow
            moveSelection(1)
        }
    }
    
    private func moveSelection(_ delta: Int) {
        guard !store.items.isEmpty else { return }
        
        // Find current index
        let currentIndex = store.items.firstIndex(where: { $0.id == selectionId }) ?? -1
        
        var newIndex = currentIndex + delta
        newIndex = max(0, min(newIndex, store.items.count - 1))
        
        selectionId = store.items[newIndex].id
    }
}

// Helper to inject Key Event handling into SwiftUI hierarchy
struct KeyboardHandler: NSViewRepresentable {
    var onKeyDown: (NSEvent) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyView()
        view.onKeyDown = onKeyDown
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    class KeyView: NSView {
        var onKeyDown: ((NSEvent) -> Void)?
        
        override var acceptsFirstResponder: Bool { true }
        
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            // Make sure we become first responder when shown
            window?.makeFirstResponder(self)
        }
        
        override func keyDown(with event: NSEvent) {
            onKeyDown?(event)
        }
    }
}

# ClipPai - macOS Clipboard Manager

## 📋 Proje Özeti

ClipPai, macOS için bir clipboard manager uygulamasıdır. Kopyalanan tüm içerikleri (metin ve resim) yakalar, listeler ve `Cmd+Shift+V` kısayolu ile hızlıca yapıştırmayı sağlar.

## 🛠 Teknoloji Stack

| Teknoloji | Kullanım Amacı |
|-----------|----------------|
| **Swift 5** | Ana programlama dili |
| **SwiftUI** | UI framework |
| **AppKit** | NSPasteboard, NSPanel, NSEvent |
| **CGEvent** | Global hotkey yakalama |

## 📁 Proje Yapısı

```
ClipPai/
├── ClipPai.xcodeproj
├── ClipPai/
│   ├── ClipPaiApp.swift          # App entry point
│   ├── Info.plist                 # App configuration
│   ├── ClipPai.entitlements       # Permissions
│   │
│   ├── Models/
│   │   └── ClipboardItem.swift    # Clipboard item data model
│   │
│   ├── Services/
│   │   ├── ClipboardMonitor.swift # Clipboard değişiklik izleme
│   │   ├── ClipboardStore.swift   # Clipboard history yönetimi
│   │   ├── HotkeyManager.swift    # Global hotkey yakalama
│   │   └── PasteService.swift     # Yapıştırma işlemi
│   │
│   ├── Views/
│   │   ├── ClipboardPopupView.swift   # Ana popup view
│   │   └── ClipboardItemRow.swift     # Liste satır görünümü
│   │
│   └── Controllers/
│       └── PopupWindowController.swift # Popup pencere yönetimi
│
└── Assets.xcassets/
    └── AppIcon.appiconset/        # Uygulama ikonu
```

---

## 🚀 Geliştirme Adımları

### Aşama 1: Proje Kurulumu

- [ ] **1.1 Xcode Projesi Oluşturma**
  ```bash
  # Xcode'da: File > New > Project > macOS > App
  # Product Name: ClipPai
  # Interface: SwiftUI
  # Language: Swift
  # Bundle Identifier: com.yourname.clippai
  ```

- [ ] **1.2 Info.plist Ayarları**
  ```xml
  <!-- Menu bar only app (dock'ta görünmesin) -->
  <key>LSUIElement</key>
  <true/>
  
  <!-- Accessibility açıklaması -->
  <key>NSAppleEventsUsageDescription</key>
  <string>ClipPai needs accessibility access to paste content.</string>
  ```

- [ ] **1.3 Entitlements**
  ```xml
  <key>com.apple.security.automation.apple-events</key>
  <true/>
  ```

---

### Aşama 2: Data Model

- [ ] **2.1 ClipboardItem.swift**
  ```swift
  import AppKit

  enum ClipboardItemType {
      case text(String)
      case image(NSImage)
  }

  struct ClipboardItem: Identifiable {
      let id = UUID()
      let type: ClipboardItemType
      let timestamp = Date()
      
      var preview: String {
          switch type {
          case .text(let str):
              return String(str.prefix(100))
          case .image:
              return "[Image]"
          }
      }
  }
  ```

---

### Aşama 3: Clipboard Monitoring

- [ ] **3.1 ClipboardMonitor.swift**
  
  NSPasteboard polling ile clipboard değişikliklerini izle:
  
  ```swift
  import AppKit
  import Combine

  class ClipboardMonitor: ObservableObject {
      private var timer: Timer?
      private var lastChangeCount: Int = 0
      
      var onNewItem: ((ClipboardItem) -> Void)?
      
      func start() {
          lastChangeCount = NSPasteboard.general.changeCount
          timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
              self?.checkClipboard()
          }
      }
      
      private func checkClipboard() {
          let pasteboard = NSPasteboard.general
          guard pasteboard.changeCount != lastChangeCount else { return }
          lastChangeCount = pasteboard.changeCount
          
          // Text kontrolü
          if let text = pasteboard.string(forType: .string) {
              let item = ClipboardItem(type: .text(text))
              onNewItem?(item)
              return
          }
          
          // Image kontrolü
          if let imageData = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png),
             let image = NSImage(data: imageData) {
              let item = ClipboardItem(type: .image(image))
              onNewItem?(item)
          }
      }
      
      func stop() {
          timer?.invalidate()
          timer = nil
      }
  }
  ```

- [ ] **3.2 ClipboardStore.swift**
  ```swift
  import Foundation

  class ClipboardStore: ObservableObject {
      @Published var items: [ClipboardItem] = []
      private let maxItems = 50
      
      func add(_ item: ClipboardItem) {
          // Duplicate check (son item ile aynıysa ekleme)
          if let lastItem = items.first {
              if isSame(lastItem, item) { return }
          }
          
          items.insert(item, at: 0)
          if items.count > maxItems {
              items.removeLast()
          }
      }
      
      private func isSame(_ a: ClipboardItem, _ b: ClipboardItem) -> Bool {
          switch (a.type, b.type) {
          case (.text(let t1), .text(let t2)):
              return t1 == t2
          default:
              return false
          }
      }
  }
  ```

---

### Aşama 4: Global Hotkey

- [ ] **4.1 HotkeyManager.swift**
  
  CGEvent tap ile Cmd+Shift+V yakala:
  
  ```swift
  import Cocoa

  class HotkeyManager {
      private var eventTap: CFMachPort?
      var onHotkey: (() -> Void)?
      
      func start() {
          let eventMask = (1 << CGEventType.keyDown.rawValue)
          
          guard let tap = CGEvent.tapCreate(
              tap: .cgSessionEventTap,
              place: .headInsertEventTap,
              options: .defaultTap,
              eventsOfInterest: CGEventMask(eventMask),
              callback: { proxy, type, event, refcon in
                  let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon!).takeUnretainedValue()
                  return manager.handleEvent(proxy: proxy, type: type, event: event)
              },
              userInfo: Unmanaged.passUnretained(self).toOpaque()
          ) else {
              print("Failed to create event tap. Check Accessibility permissions.")
              return
          }
          
          eventTap = tap
          let runLoopSource = CFMachPortCreateRunLoopSource(nil, tap, 0)
          CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
          CGEvent.tapEnable(tap: tap, enable: true)
      }
      
      private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
          if type == .keyDown {
              let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
              let flags = event.flags
              
              // V key = 9, Cmd+Shift
              if keyCode == 9 &&
                 flags.contains(.maskCommand) &&
                 flags.contains(.maskShift) {
                  DispatchQueue.main.async {
                      self.onHotkey?()
                  }
                  return nil // Event'i consume et
              }
          }
          return Unmanaged.passRetained(event)
      }
  }
  ```

  > ⚠️ **ÖNEMLİ:** Bu kod çalışması için System Preferences > Privacy & Security > Accessibility'den izin gerekir.

---

### Aşama 5: Popup UI

- [ ] **5.1 PopupWindowController.swift**
  ```swift
  import AppKit
  import SwiftUI

  class PopupWindowController {
      private var panel: NSPanel?
      private var store: ClipboardStore
      var onSelect: ((ClipboardItem) -> Void)?
      
      init(store: ClipboardStore) {
          self.store = store
      }
      
      func show() {
          let contentView = ClipboardPopupView(store: store) { [weak self] item in
              self?.hide()
              self?.onSelect?(item)
          }
          
          let panel = NSPanel(
              contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
              styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
              backing: .buffered,
              defer: false
          )
          
          panel.contentView = NSHostingView(rootView: contentView)
          panel.isFloatingPanel = true
          panel.level = .floating
          panel.titlebarAppearsTransparent = true
          panel.titleVisibility = .hidden
          panel.backgroundColor = .clear
          
          // Mouse pozisyonuna göre konumlandır
          let mouseLocation = NSEvent.mouseLocation
          panel.setFrameOrigin(NSPoint(
              x: mouseLocation.x - 200,
              y: mouseLocation.y - 500
          ))
          
          panel.makeKeyAndOrderFront(nil)
          self.panel = panel
      }
      
      func hide() {
          panel?.close()
          panel = nil
      }
  }
  ```

- [ ] **5.2 ClipboardPopupView.swift**
  ```swift
  import SwiftUI

  struct ClipboardPopupView: View {
      @ObservedObject var store: ClipboardStore
      var onSelect: (ClipboardItem) -> Void
      
      @State private var selectedIndex = 0
      
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
              
              // List
              ScrollViewReader { proxy in
                  List(Array(store.items.enumerated()), id: \.element.id) { index, item in
                      ClipboardItemRow(item: item, isSelected: index == selectedIndex)
                          .id(item.id)
                          .onTapGesture {
                              onSelect(item)
                          }
                  }
              }
          }
          .frame(width: 400, height: 500)
          .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
          .cornerRadius(12)
          .onKeyPress { key in
              handleKeyPress(key)
          }
      }
      
      private func handleKeyPress(_ key: KeyPress) -> KeyPress.Result {
          switch key.key {
          case .upArrow:
              selectedIndex = max(0, selectedIndex - 1)
              return .handled
          case .downArrow:
              selectedIndex = min(store.items.count - 1, selectedIndex + 1)
              return .handled
          case .return:
              if !store.items.isEmpty {
                  onSelect(store.items[selectedIndex])
              }
              return .handled
          case .escape:
              // Parent'a close sinyali gönder
              return .handled
          default:
              return .ignored
          }
      }
  }

  // Visual Effect için helper
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
  ```

- [ ] **5.3 ClipboardItemRow.swift**
  ```swift
  import SwiftUI

  struct ClipboardItemRow: View {
      let item: ClipboardItem
      let isSelected: Bool
      
      var body: some View {
          HStack(spacing: 12) {
              // Icon veya Thumbnail
              Group {
                  switch item.type {
                  case .text:
                      Image(systemName: "doc.text")
                          .font(.title2)
                          .foregroundColor(.blue)
                  case .image(let nsImage):
                      Image(nsImage: nsImage)
                          .resizable()
                          .aspectRatio(contentMode: .fill)
                          .frame(width: 40, height: 40)
                          .cornerRadius(4)
                  }
              }
              .frame(width: 40, height: 40)
              
              // Content
              VStack(alignment: .leading, spacing: 4) {
                  Text(item.preview)
                      .lineLimit(2)
                      .font(.body)
                  
                  Text(item.timestamp, style: .relative)
                      .font(.caption)
                      .foregroundColor(.secondary)
              }
              
              Spacer()
          }
          .padding(.vertical, 8)
          .padding(.horizontal, 12)
          .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
          .cornerRadius(8)
      }
  }
  ```

---

### Aşama 6: Paste İşlemi

- [ ] **6.1 PasteService.swift**
  ```swift
  import AppKit

  class PasteService {
      func paste(_ item: ClipboardItem) {
          // Önce clipboard'a koy
          let pasteboard = NSPasteboard.general
          pasteboard.clearContents()
          
          switch item.type {
          case .text(let text):
              pasteboard.setString(text, forType: .string)
          case .image(let image):
              if let tiffData = image.tiffRepresentation {
                  pasteboard.setData(tiffData, forType: .tiff)
              }
          }
          
          // Sonra Cmd+V simüle et
          simulatePaste()
      }
      
      private func simulatePaste() {
          let source = CGEventSource(stateID: .hidSystemState)
          
          // V tuşuna bas (Cmd ile)
          let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
          keyDown?.flags = .maskCommand
          
          let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
          keyUp?.flags = .maskCommand
          
          keyDown?.post(tap: .cghidEventTap)
          keyUp?.post(tap: .cghidEventTap)
      }
  }
  ```

---

### Aşama 7: App Entry Point

- [ ] **7.1 ClipPaiApp.swift**
  ```swift
  import SwiftUI
  import AppKit

  @main
  struct ClipPaiApp: App {
      @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
      
      var body: some Scene {
          Settings {
              EmptyView()
          }
      }
  }

  class AppDelegate: NSObject, NSApplicationDelegate {
      private var statusItem: NSStatusItem!
      private let clipboardMonitor = ClipboardMonitor()
      private let clipboardStore = ClipboardStore()
      private let hotkeyManager = HotkeyManager()
      private var popupController: PopupWindowController!
      private let pasteService = PasteService()
      
      func applicationDidFinishLaunching(_ notification: Notification) {
          setupStatusItem()
          setupClipboardMonitor()
          setupHotkey()
          setupPopup()
      }
      
      private func setupStatusItem() {
          statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
          
          if let button = statusItem.button {
              button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "ClipPai")
          }
          
          let menu = NSMenu()
          menu.addItem(NSMenuItem(title: "Show History (⌘⇧V)", action: #selector(showPopup), keyEquivalent: ""))
          menu.addItem(NSMenuItem.separator())
          menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
          statusItem.menu = menu
      }
      
      private func setupClipboardMonitor() {
          clipboardMonitor.onNewItem = { [weak self] item in
              self?.clipboardStore.add(item)
          }
          clipboardMonitor.start()
      }
      
      private func setupHotkey() {
          hotkeyManager.onHotkey = { [weak self] in
              self?.showPopup()
          }
          hotkeyManager.start()
      }
      
      private func setupPopup() {
          popupController = PopupWindowController(store: clipboardStore)
          popupController.onSelect = { [weak self] item in
              self?.pasteService.paste(item)
          }
      }
      
      @objc private func showPopup() {
          popupController.show()
      }
      
      @objc private func quit() {
          NSApplication.shared.terminate(nil)
      }
  }
  ```

---

## ✅ Test Senaryoları

### Test 1: Clipboard İzleme
1. Uygulamayı başlat
2. Herhangi bir metin kopyala (⌘C)
3. Menu bar ikonuna tıkla → History'de göründüğünü doğrula
4. Bir screenshot al (⌘⇧4) → History'de resim göründüğünü doğrula

### Test 2: Hotkey
1. ⌘⇧V'ye bas
2. Popup penceresinin açıldığını doğrula
3. ESC ile kapandığını doğrula

### Test 3: Yapıştırma
1. TextEdit veya Notes aç
2. ⌘⇧V ile popup aç
3. Arrow keys ile gezin
4. Enter ile seç
5. İçeriğin yapıştırıldığını doğrula

### Test 4: Resim Yapıştırma
1. Preview'da bir resim aç, ⌘C ile kopyala
2. ⌘⇧V ile popup aç
3. Resmi seç
4. Yapıştırıldığını doğrula

---

## ⚠️ Bilinen Kısıtlamalar

1. **Accessibility İzni:** Uygulama ilk açılışta System Preferences'dan izin ister. İzin verilmeden hotkey çalışmaz.

2. **Sandbox:** App Store dağıtımı için sandbox kısıtlamaları geçerli. Local dağıtımda sorun yok.

3. **Memory:** Büyük resimler memory kullanımını artırır. Opsiyonel olarak thumbnail oluşturma eklenebilir.

---

## 🔮 Gelecek Özellikler (Opsiyonel)

- [ ] Arama/filtreleme
- [ ] Kalıcı depolama (SQLite veya UserDefaults)
- [ ] Favoriler sistemi
- [ ] Özelleştirilebilir hotkey
- [ ] Syntax highlighting (kod için)
- [ ] iCloud sync
- [ ] Temizleme/silme özellikleri

---

## 🔧 Build & Run

```bash
# Xcode'da aç
open ClipPai.xcodeproj

# Terminal'den build
xcodebuild -scheme ClipPai -configuration Debug build

# Uygulamayı çalıştır
open build/Debug/ClipPai.app
```

---

## 📚 Referanslar

- [NSPasteboard Documentation](https://developer.apple.com/documentation/appkit/nspasteboard)
- [CGEvent Reference](https://developer.apple.com/documentation/coregraphics/cgevent)
- [SwiftUI for macOS](https://developer.apple.com/documentation/swiftui)
- [Menu Bar Apps Tutorial](https://www.raywenderlich.com/450-menus-and-popovers-in-menu-bar-apps-for-macos)

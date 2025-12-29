import Cocoa

class HotkeyManager {
    private var eventTap: CFMachPort?
    var onHotkey: (() -> Void)?
    
    func start() {
        // We want to capture KeyDown events
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
            
            // Key Code 9 is 'V' on ANSI keyboard
            // We check for Command + Shift + V
            if keyCode == 9 &&
               flags.contains(.maskCommand) &&
               flags.contains(.maskShift) {
                
                // Dispatch to main thread
                DispatchQueue.main.async {
                    self.onHotkey?()
                }
                
                // Return nil to consume the event so it doesn't propagate
                return nil
            }
        }
        return Unmanaged.passRetained(event)
    }
    
    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            eventTap = nil
        }
    }
}

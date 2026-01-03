# Clippai

Clippai is a macOS clipboard manager that captures copied text and images, keeps a local history, and opens a fast "Quick Paste" panel with Cmd+Shift+V.

## Features
- Tracks text and image clipboard entries
- Menu bar app with a full history window
- Quick Paste panel with keyboard navigation and one-click paste
- Local-only storage (no network usage)
- Duplicate suppression (same content moves to the top instead of duplicating)

## Requirements
- macOS 13+
- Xcode 15+

## Setup
1) Open the project:

```sh
open Clippai.xcodeproj
```

2) In Xcode, select the `Clippai` target and set:
- Team (Signing & Capabilities)
- Bundle Identifier (default: `com.developcu.clippai`)

3) Run:
```
Product > Run
```

## Permissions
Clippai sends Cmd+V to the active app, which requires Accessibility permission:

1) System Settings > Privacy & Security > Accessibility
2) Enable "Clippai"

If you see a log like:
```
Unable to obtain a task name port right for pid ...
```
it almost always means Accessibility is not granted yet.

## Usage
- Copy text or an image: Clippai captures it automatically.
- Open Quick Paste: `Cmd+Shift+V`
- Navigate with arrow keys, press Enter to paste
- Click an item to paste immediately

## Where Data Is Stored
All data is local:
- `~/Library/Application Support/clippai/items.json`
- `~/Library/Application Support/clippai/images/`

## Architecture (High Level)
- `ClipboardMonitor`: polls the NSPasteboard change count
- `ClipboardStore`: in-memory + disk persistence, dedupe, image storage
- `HotkeyManager`: global Cmd+Shift+V
- `PasteController`: writes to pasteboard, triggers Cmd+V
- SwiftUI views for history and Quick Paste panel

## Troubleshooting
**Quick Paste does not appear**
- Check if another app uses Cmd+Shift+V
- Make sure the app is running (menu bar icon visible)

**Paste does not happen**
- Ensure Accessibility permission is enabled

**Build error about entitlements being modified**
- Use the provided Debug/Release entitlements files in the project

## Roadmap Ideas
- Search filters and pinning
- Customizable hotkey
- Rich previews for large images and text

## License
MIT. See `LICENSE`.

# Feature Implementation Status & Specifications

This document tracks the comprehensive implementation status, permissions required, source location, and roadmap of features in **Handy**.

---

## 1. Feature Matrix & Implementation Overview

| Feature Name | Category | Status | Code Location | Required Permissions |
|---|---|---|---|---|
| **Cut & Paste Files** | Finder / Keyboard | **Implemented** | [FinderCutPaste.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/App/FinderCutPaste.swift), [EventTap.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/App/EventTap.swift) | Accessibility, Finder Automation |
| **Open with Return** | Finder / Keyboard | **Implemented** | [EventTap.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/App/EventTap.swift) | Accessibility, Finder Automation |
| **Copy Path** | Context Menu | **Implemented** | [FinderSyncExtension.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/Extension/FinderSyncExtension.swift) | Finder Extension |
| **Open in Terminal** | Context Menu | **Implemented** | [FinderSyncExtension.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/Extension/FinderSyncExtension.swift) | Finder Extension |
| **New .txt File Here** | Context Menu | **Implemented** | [FinderSyncExtension.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/Extension/FinderSyncExtension.swift), [FileNaming.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/Shared/FileNaming.swift) | Finder Extension |
| **Extract All Here** | Context Menu | **Implemented** | [FinderSyncExtension.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/Extension/FinderSyncExtension.swift) | Finder Extension |
| **Bluetooth Off on Sleep** | System Power | **Implemented** | [Bluetooth.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/App/Bluetooth.swift) | None (IOBluetooth Private API) |
| **Keep Awake** | System Power | **Implemented** | [KeepAwake.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/App/KeepAwake.swift) | None (`caffeinate` binary) |
| **Show Hidden Files** | System / Finder | **Implemented** | [SettingsView.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/App/SettingsView.swift) | `com.apple.finder` domain write |
| **Toggle Dark Mode** | System Appearance | **Implemented** | [SettingsView.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/App/SettingsView.swift) | System Events Automation |
| **Empty Trash** | Utility / Maintenance | **Implemented** | [SettingsView.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/App/SettingsView.swift) | Finder Automation |
| **EdDSA Auto-Updates** | Distribution | **Implemented** | [main.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/App/main.swift) | Network access |
| **Delete Immediately** | Context Menu / Keyboard | **Planned** (Coming Soon) | UI placeholder in [SettingsView.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/App/SettingsView.swift#L194) | Accessibility, Finder Automation |
| **Custom Global Shortcuts**| Configuration | **Planned** (Coming Soon) | UI placeholder in [SettingsView.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/App/SettingsView.swift#L411) | None |

---

## 2. Detailed Feature Specifications

### 2.1 Cut & Paste Files (`⌘X` / `⌘V` / `⌘Z` / `Esc`)
- **User Experience**: Select files in Finder and press `⌘X`. Selected items dim or become staged. Navigate to target folder and press `⌘V` to move them. `⌘Z` reverses the move. `Esc` or `⌘C` cancels the pending cut operation.
- **Technical Engine**:
  - `CGEventTap` intercepts physical keystrokes (`⌘X` virtual keycode 7, `⌘V` keycode 9, `⌘Z` keycode 6, `Esc` keycode 53).
  - AppleScript extracts the selected item URLs from Finder: `tell application "Finder" to get selection`.
  - [FinderCutPaste.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/App/FinderCutPaste.swift) executes file relocation using `FileManager.default.moveItem`.
  - Conflicts are resolved automatically using [FileNaming.uniqueDestination](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/Shared/FileNaming.swift) (e.g. `document (2).pdf`).

### 2.2 Open with Return
- **User Experience**: Highlight a file or folder in Finder and press `Return` to open it immediately.
- **Text Editing Safety Guard**:
  - Handy checks Accessibility APIs (`AXUIElementCopyAttributeValue` for `kAXFocusedUIElementAttribute`) to ensure the focused element is NOT an `AXTextField` (which indicates the user is renaming a file).
  - Pressing `Shift+Return` allows standard file renaming without triggering open.

### 2.3 FinderSync Right-Click Context Menu Actions
Provided by [FinderSyncExtension.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/Extension/FinderSyncExtension.swift) (`com.lonfeng.handy.extension`):
1. **Copy Path**: Writes target file's raw POSIX path to `NSPasteboard.general`.
2. **Open in Terminal**: Inspects installed terminal applications. If `iTerm2` (`com.googlecode.iterm2`) is detected, opens via iTerm2; otherwise falls back to `/System/Applications/Utilities/Terminal.app`.
3. **New .txt File Here**: Creates an empty file named `Untitled.txt` in the active Finder directory. If `Untitled.txt` exists, creates `Untitled (2).txt` using [FileNaming.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/Shared/FileNaming.swift).
4. **Extract All Here**: Uncompresses `.zip` archives directly into the current directory. Automatically filters out `__MACOSX` metadata folders and dot-underscore resource fork files.

### 2.4 Power Management Tweaks
1. **Bluetooth Off on Sleep**:
   - Managed by [BluetoothSleepFeature](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/App/Bluetooth.swift).
   - Dynamically checks `IOBluetoothPreferenceSetControllerPowerState` availability via Objective-C runtime linkage (`IOBluetooth.framework`).
   - Powers off Bluetooth radio upon receiving `NSWorkspace.willSleepNotification` and restores original power state on `NSWorkspace.didWakeNotification`.
2. **Keep Awake**:
   - Managed by [KeepAwake](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/App/KeepAwake.swift).
   - Launches child process `/usr/bin/caffeinate -d -i -m -s`. Terminated cleanly when toggled off or on `applicationWillTerminate`.

---

## 3. Required Permissions Matrix

| Permission Type | macOS System Settings Path | Used For |
|---|---|---|
| **Finder Extension** | System Settings → General → Login Items & Extensions → Finder Extensions | Context menu items (Copy Path, Open in Terminal, New .txt, Extract) |
| **Accessibility** | System Settings → Privacy & Security → Accessibility | Global `CGEventTap` interception of `⌘X`, `⌘V`, `⌘Z`, `Return` |
| **Finder Automation** | System Settings → Privacy & Security → Automation → Finder | AppleScript queries for Finder selection and empty trash execution |
| **Login Item** | System Settings → General → Login Items & Extensions → Open at Login | ServiceManagement registration for start on system boot |

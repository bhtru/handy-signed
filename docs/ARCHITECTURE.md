# Technical System Architecture & Internal Subsystems

This document provides an in-depth architectural deep-dive into **Handy** for core contributors, system architects, and internal AI coding agents.

---

## 1. High-Level Architecture Overview

Handy is built as a lightweight, modular macOS application without Xcode workspace overhead. The application consists of three primary compiled modules and a separate marketing website:

```text
                                 ┌──────────────────────────────────────────┐
                                 │              Handy.app                   │
                                 │                                          │
                                 │   ┌──────────────────────────────────┐   │
                                 │   │        AppDelegate / Menu        │   │
                                 │   └────────────────┬─────────────────┘   │
                                 │                    │                     │
                                 │     ┌──────────────┴──────────────┐      │
                                 │     ▼                             ▼      │
                                 │  CGEventTap               SwiftUI Settings│
                                 │  (Key Interceptor)        (4-Tab Controller)│
                                 │     │                             │      │
                                 │     └──────────────┬──────────────┘      │
                                 │                    ▼                     │
                                 │           FinderCutPaste Engine          │
                                 │                    │                     │
                                 └────────────────────┼─────────────────────┘
                                                      │
                       ┌──────────────────────────────┼──────────────────────────────┐
                       │                              │                              │
                       ▼                              ▼                              ▼
          ┌─────────────────────────┐   ┌───────────────────────────┐   ┌─────────────────────────┐
          │  FinderSync Extension   │   │     Shared Domain Core    │   │  Sparkle Update Engine  │
          │ (com.lonfeng.handy.ext) │   │ (FileNaming.uniqueDest.)  │   │  (SPUStandardUpdater)   │
          └─────────────────────────┘   └───────────────────────────┘   └─────────────────────────┘
```

---

## 2. Main App Subsystems ([Sources/App/](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/App/))

### 2.1 AppDelegate & Menu Bar Controller ([main.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/App/main.swift))
- Runs in `.accessory` activation policy mode (menu bar icon only, no Dock icon by default).
- When Settings window is shown, switches dynamically to `.regular` activation policy so system menus and window titlebars act like a standard application, and reverts to `.accessory` upon window close.
- Draws custom single-color vector menu bar icon procedurally in `makeHandyStatusIcon()`.
- Runs persistent 3-second watchdog timer to ensure `CGEventTap` remains active across macOS system sleep/wake cycles or accessibility permission state changes.

### 2.2 Global Key Interception via CGEventTap ([EventTap.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/App/EventTap.swift))
- Uses CoreGraphics `CGEvent.tapCreate` targeting `kCGHIDEventTap` placed at `kCGHeadInsertEventTap`.
- **Filtering Logic**:
  1. Checks if frontmost application is Finder (`com.apple.finder`).
  2. Filters `keyDown` events matching specific keycodes:
     - `⌘X` (Keycode 7) -> Triggers `FinderCutPaste.shared.cut()`
     - `⌘V` (Keycode 9) -> Triggers `FinderCutPaste.shared.paste()`
     - `⌘Z` (Keycode 6) -> Triggers `FinderCutPaste.shared.undo()`
     - `Esc` (Keycode 53) -> Clears pending cut state
     - `Return` (Keycode 36) -> Triggers `open selection`
- **Inline Text Edit Guard**: Before processing `Return`, queries Accessibility API (`AXUIElementCopyAttributeValue` for `kAXFocusedUIElementAttribute`). If focused element role is `AXTextField`, keypress is ignored so user can rename files normally.

### 2.3 File Move & Cut/Paste Engine ([FinderCutPaste.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/App/FinderCutPaste.swift))
- Maintains in-memory staging state of copied POSIX paths.
- Uses AppleScript via [AppleScriptRunner.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/App/AppleScriptRunner.swift) to retrieve active Finder selection and destination path.
- Executes file relocation using `FileManager.default.moveItem`.
- Resolves file collisions safely using [FileNaming.uniqueDestination](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/Shared/FileNaming.swift), incrementing names (e.g. `file (2).pdf`).
- Records undo stack allowing `⌘Z` reversal.

### 2.4 Serialized AppleScript Execution ([AppleScriptRunner.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/App/AppleScriptRunner.swift))
- `NSAppleScript` execution in macOS is non-thread-safe and susceptible to main-thread hangs if Finder is unresponsive.
- [AppleScriptRunner.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/App/AppleScriptRunner.swift) wraps execution in a dedicated background serial `DispatchQueue`, enforcing timeouts and preventing main thread deadlocks.

### 2.5 Bluetooth Sleep Manager ([Bluetooth.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/App/Bluetooth.swift))
- Integrates with private `IOBluetooth.framework` using Objective-C runtime dynamic resolution (`NSClassFromString("IOBluetoothPreferenceSetController")`).
- Listens for `NSWorkspace.willSleepNotification` and `NSWorkspace.didWakeNotification`.
- Powers off Bluetooth controller state on sleep and restores original power state on wake.

---

## 3. FinderSync Extension Subsystem ([Sources/Extension/](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/Extension/))

- Located in `Sources/Extension/FinderSyncExtension.swift` (`com.lonfeng.handy.extension`).
- Inherits from `FIFinderSync`.
- Registers interest in `/` (root) and user home directory via `FIFinderSyncController.default().directoryURLs`.
- Implements `menu(for menuKind: FIFinderSyncMenuKind)` to inject right-click context items into standard macOS Finder menus:
  - `Copy Path`: Accesses `FIFinderSyncController.default().selectedItemURLs()` and copies string representations to `NSPasteboard`.
  - `Open in Terminal`: Queries `NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.googlecode.iterm2")` to launch iTerm2 or falls back to `/System/Applications/Utilities/Terminal.app`.
  - `New .txt File Here`: Derives target directory from `targetURL()`, generating non-conflicting `Untitled.txt` filename using shared logic.
  - `Extract All Here`: Extracts `.zip` files while stripping OS metadata (`__MACOSX`).

---

## 4. Build Pipeline & Script Mechanics ([build.sh](file:///Users/brandontruong/Documents/Personal/handy-signed/build.sh))

The build process is managed by [build.sh](file:///Users/brandontruong/Documents/Personal/handy-signed/build.sh) across 8 explicit phases:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│ 1. Type-check        │ Catches compile errors via swiftc -typecheck         │
├──────────────────────┼──────────────────────────────────────────────────────┤
│ 2. Unit Tests        │ Compiles Sources/Shared/ + Tests/ & runs binary      │
├──────────────────────┼──────────────────────────────────────────────────────┤
│ 3. Clean & Structure │ Assembles .app bundle directory hierarchy             │
├──────────────────────┼──────────────────────────────────────────────────────┤
│ 4. Asset Generation  │ Compiles Swift icon generator into Handy.iconset     │
├──────────────────────┼──────────────────────────────────────────────────────┤
│ 5. Compilation       │ Compiles App binary & FinderSync Extension binary    │
├──────────────────────┼──────────────────────────────────────────────────────┤
│ 6. Version Stamping  │ PlistBuddy stamps VERSION into both Info.plists      │
├──────────────────────┼──────────────────────────────────────────────────────┤
│ 7. Inside-Out Signing│ Signs Sparkle helpers → Framework → Extension → App   │
├──────────────────────┼──────────────────────────────────────────────────────┤
│ 8. Packaging & Notary│ Creates UDRW DMG, runs AppleScript layout, converts  │
│                      │ to compressed UDZO DMG, signs & notarizes with Apple │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 5. TCC Security Reset Architecture

Because macOS ties Accessibility and Automation permissions to code signatures, rebuilding an ad-hoc signed binary breaks TCC trust.

In [SettingsView.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/App/SettingsView.swift), the `requestAccess()` helper automatically invokes:
```bash
/usr/bin/tccutil reset Accessibility com.lonfeng.handy
/usr/bin/tccutil reset AppleEvents com.lonfeng.handy
```
This flushes stale permission records, allowing the user to seamlessly grant access to the newly compiled binary without manual system troubleshooting.

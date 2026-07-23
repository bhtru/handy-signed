# AI Agent Guide & Repository Manual

Welcome to **Handy** (`handy-signed`). This document provides comprehensive context, architectural principles, repo maps, and guidelines for internal team members and internal AI coding agents working in this repository.

---

## 1. Executive Summary & Product Architecture

**Handy** is a lightweight macOS menu-bar utility (macOS 13+ Ventura or later) designed to add missing Finder conveniences and system utility tweaks.

Key technical characteristics:
- **No Xcode Project**: Handy uses a pure CLI Swift build system driven by [build.sh](file:///Users/brandontruong/Documents/Personal/handy-signed/build.sh) using `swiftc` directly.
- **Inside-Out Code Signing**: Custom code-signing logic handles nested frameworks (Sparkle), FinderSync App Extensions, and entitlements.
- **Multi-Process Architecture**:
  - Main App ([Sources/App/main.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/App/main.swift)): SwiftUI settings, menu bar item (`NSStatusItem`), `CGEventTap` keyboard interceptor, and background workers.
  - Finder Extension ([Sources/Extension/FinderSyncExtension.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/Extension/FinderSyncExtension.swift)): A `FIFinderSync` app extension providing context menu integration in Finder (Path copying, Open in Terminal, New .txt File, ZIP extraction).
  - Shared Module ([Sources/Shared/FileNaming.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/Shared/FileNaming.swift)): Shared pure logic compiled into both main app and unit test suite.
- **Astro Marketing Site**: Static website with MDX blog support hosted under [src/](file:///Users/brandontruong/Documents/Personal/handy-signed/src/).

---

## 2. Directory Structure & Quick Map

```text
handy-signed/
├── AGENTS.md                  # This file — AI agent instruction manual & repo guide
├── VERSION                    # Single source of truth for app version (e.g. 1.0.0)
├── build.sh                   # Main build, test, sign, notarize & package script
├── release.sh                 # Release automation & GitHub Releases publisher
├── create_icon.swift          # Programmatic icon generator
├── docs/                      # Central documentation hub
│   ├── README.md              # Documentation index and hub sitemap
│   ├── FEATURES.md            # Detailed status of all feature implementations
│   ├── TESTING.md             # Testing architecture, test cases & CI setup
│   ├── RELEASES_AND_DEPLOYMENT.md # Release status, signing & notarization guide
│   ├── USER_GUIDE.md          # User manual, permission guides & troubleshooting
│   └── ARCHITECTURE.md       # Technical deep-dive into main app & extension
├── Sources/
│   ├── App/                   # Menu-bar app (SwiftUI, EventTap, AppleScript)
│   │   ├── main.swift         # Entry point, status item, AppDelegate
│   │   ├── SettingsView.swift # 4-tab SwiftUI settings UI
│   │   ├── EventTap.swift     # Low-level CGEventTap for keyboard interception
│   │   ├── FinderCutPaste.swift # File move/cut/paste execution & undo engine
│   │   ├── KeepAwake.swift    # caffeinate process management wrapper
│   │   ├── Bluetooth.swift    # Private IOBluetooth sleep/wake listener
│   │   ├── AppleScriptRunner.swift # Serialized NSAppleScript engine
│   │   ├── Info.plist         # App bundle plist configuration
│   │   └── app.entitlements   # App entitlements
│   ├── Extension/             # FinderSync context menu extension
│   │   ├── FinderSyncExtension.swift # Context menu actions & ZIP extraction
│   │   ├── Info.plist         # Extension plist metadata
│   │   └── extension.entitlements # Extension entitlements
│   └── Shared/                # Logic shared between App & Tests
│       └── FileNaming.swift   # Non-conflicting filename generator logic
├── Tests/
│   └── main.swift             # Standalone unit test suite runner
├── scripts/
│   └── setup-apple-signing.sh # Keychain profile helper for notarytool
└── src/                       # Astro web application for marketing & blog
```

---

## 3. Core Development & Verification Workflows

### Type-Check & Run Unit Tests (Fast CI Check)
```bash
bash build.sh --check
```
*Always run `bash build.sh --check` before submitting any code changes or declaring task completion.*

### Full Build (Local Ad-Hoc Signed DMG)
```bash
bash build.sh
```
*Compiles app, generates icons, signs ad-hoc, runs verification, and produces `Handy.dmg`.*

### Developer ID Signed & Notarized Build
```bash
SIGNING_IDENTITY="3E901352041D52C4625F6D37ADEEAD3A6AD00CBA" \
NOTARY_PROFILE=handy-notary-tsuga \
NOTARIZE=1 \
bash build.sh
```

### Web Development Commands
```bash
npm run dev     # Launch local Astro dev server
npm run build   # Build production distribution into dist/
npm run preview # Preview dist/ output
```

---

## 4. Key Engineering Conventions & Rules for AI Agents

1. **Version Control as Single Source of Truth**:
   - The version string is stored solely in [VERSION](file:///Users/brandontruong/Documents/Personal/handy-signed/VERSION). Never hardcode version strings in Plists; [build.sh](file:///Users/brandontruong/Documents/Personal/handy-signed/build.sh) stamps [VERSION](file:///Users/brandontruong/Documents/Personal/handy-signed/VERSION) into `Info.plist` dynamically.

2. **Shared Code Isolation**:
   - Code that needs test coverage must be placed in [Sources/Shared/](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/Shared/). [Tests/main.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Tests/main.swift) directly compiles files in [Sources/Shared/](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/Shared/) to test real production binaries without mock overhead.

3. **Code Signing Order (Inside-Out)**:
   - When updating code signing scripts, sign nested helpers inside `Sparkle.framework` first, then `Sparkle.framework`, then `Handy Extension.appex`, and finally `Handy.app`. Violating this order breaks deep strict signature verification (`codesign --verify --strict --deep`).

4. **TCC & Accessibility Permissions Handling**:
   - Ad-hoc builds change signatures on every rebuild, rendering TCC Accessibility permissions stale.
   - Handy includes an automated reset loop using `tccutil reset` in [SettingsView.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/App/SettingsView.swift) to ensure users do not get stuck with invalid grants. Do not modify or bypass this mechanism without careful testing.

5. **Sanitation & Process Cleanup**:
   - Background tasks like `caffeinate` managed by [KeepAwake.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/App/KeepAwake.swift) must be explicitly terminated in `applicationWillTerminate` to avoid orphaned processes keeping system hardware awake indefinitely.

---

## 5. Documentation Hub Reference

For detailed documentation, refer to the files in [docs/](file:///Users/brandontruong/Documents/Personal/handy-signed/docs):
- [docs/README.md](file:///Users/brandontruong/Documents/Personal/handy-signed/docs/README.md): Documentation index and hub overview.
- [docs/FEATURES.md](file:///Users/brandontruong/Documents/Personal/handy-signed/docs/FEATURES.md): Implementation matrix and feature specification.
- [docs/TESTING.md](file:///Users/brandontruong/Documents/Personal/handy-signed/docs/TESTING.md): Testing strategy, unit test coverage, manual QA suite.
- [docs/RELEASES_AND_DEPLOYMENT.md](file:///Users/brandontruong/Documents/Personal/handy-signed/docs/RELEASES_AND_DEPLOYMENT.md): Signed release status, Sparkle updater pipeline, and deployment checklist.
- [docs/USER_GUIDE.md](file:///Users/brandontruong/Documents/Personal/handy-signed/docs/USER_GUIDE.md): End-user manual, feature interactions, and permission walkthroughs.
- [docs/ARCHITECTURE.md](file:///Users/brandontruong/Documents/Personal/handy-signed/docs/ARCHITECTURE.md): Technical deep-dive into event taps, AppleScript serialization, and process boundaries.

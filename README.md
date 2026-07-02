# Handy

A lightweight macOS menu-bar utility that adds the small Finder conveniences macOS leaves out.

## Features

| Feature | How to use |
|---|---|
| **Cut & Paste files** | `⌘X` on selected files in Finder, `⌘V` in another folder — a real move, not a copy. `⌘Z` undoes the move. `Esc` or `⌘C` cancels a pending cut. |
| **Open with Return** | Press `Return` to open the selected item (instead of renaming it). Renaming still works — Handy never interferes while you're editing a name. |
| **Copy Path** | Right-click any file → *Copy Path* |
| **Open in Terminal** | Right-click a folder → *Open in Terminal* (uses iTerm2 if installed) |
| **New .txt File Here** | Right-click empty space in a folder → *New .txt File Here* |
| **Extract All Here** | Right-click a `.zip` → *Extract All Here* (no `__MACOSX` junk) |
| **Bluetooth off on sleep** | Optionally turns Bluetooth off when the Mac sleeps, back on at wake |
| **Keep Awake** | Stops the screen and system from sleeping |
| **Empty Trash** | From the Tools tab, using Finder (handles external volumes) |

Requires **macOS 13 (Ventura) or later**.

## Install

1. Download the latest `Handy-x.y.z.dmg` from [Releases](https://github.com/IsaacYeung/Handy/releases)
2. Open the DMG and drag **Handy** into **Applications**
3. Launch Handy from Applications
   - If macOS says the app is from an unidentified developer: right-click **Handy.app** → **Open** → **Open**. (This happens because current builds are not yet notarized.)
4. Follow the setup below — Handy's Settings window opens automatically on first launch.

### Setting up permissions

Handy needs up to three permissions, depending on which features you enable:

| Permission | Needed for | How to grant |
|---|---|---|
| **Finder Extension** | Right-click menu items | System Settings → General → Login Items & Extensions → Finder Extensions → enable *Handy Extension*. The **General** tab shows live status. |
| **Accessibility** | `⌘X`/`⌘V`/`⌘Z`/Return keyboard features | Click **Grant Access** on the **General** tab, then toggle Handy **ON** in the list that opens. |
| **Automation (Finder)** | Cut/paste and Return-to-open | macOS asks *"Handy wants to control Finder"* the first time — click **Allow**. |

If a keyboard feature ever stops working (for example after an update to an unsigned build), open the **General** tab and click **Grant Access** again — Handy clears its stale permission entry automatically and walks you through re-enabling. No need to remove anything by hand.

### Updates

Handy checks for updates automatically and has **Check for Updates…** in its menu-bar menu. Updates are delivered from GitHub Releases and are EdDSA-signed — the app only installs updates signed with the project's private key.

## Building from source

Requirements: macOS 13+, Xcode Command Line Tools (`xcode-select --install`).

```sh
git clone https://github.com/IsaacYeung/Handy.git
cd Handy
bash build.sh
```

`build.sh` runs the full pipeline and produces `Handy.dmg`:

1. **Fetch** — downloads Sparkle (pinned version) into `vendor/` on first run
2. **Type-check** — all sources, before anything is built
3. **Test** — unit tests in `Tests/` (they compile `Sources/Shared/` so they exercise real production code)
4. **Compile** — app + FinderSync extension via `swiftc` (no Xcode project)
5. **Stamp** — writes the version from the `VERSION` file into both Info.plists
6. **Sign** — inside-out: Sparkle helpers → framework → extension → app
7. **Verify** — bundle structure and signature validity
8. **Package** — styled DMG installer

CI runs `bash build.sh --check` (steps 1–3 only) on every push and pull request.

### Signing

By default builds are **ad-hoc signed** — fine for local use, but macOS ties permissions to the code signature, so every rebuild invalidates previous permission grants. For distributable builds, sign with a Developer ID:

```sh
SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)" bash build.sh
```

This enables the Hardened Runtime and secure timestamps, making the build notarizable, and permissions then persist across updates.

## Releasing

```sh
# 1. Bump the version
echo "1.1.0" > VERSION

# 2. Commit everything (release.sh refuses to run with uncommitted changes)
git add -A && git commit -m "Release 1.1.0"

# 3. Build, sign the update, generate the appcast, publish to GitHub Releases
SIGNING_IDENTITY="Developer ID Application: …" bash release.sh
```

`release.sh` signs the DMG with the Sparkle EdDSA key (stored in the releaser's Keychain — generated once with `vendor/Sparkle/bin/generate_keys`), regenerates `appcast.xml`, and creates the GitHub release. Existing installs pick the update up automatically.

## Project layout

```
Sources/
  App/               Menu-bar app (SwiftUI settings, event tap, features)
    main.swift            App delegate, status item, settings window
    SettingsView.swift    4-tab settings UI (General / Tweaks / Shortcuts / Tools)
    EventTap.swift        Global keyboard interception (CGEventTap)
    FinderCutPaste.swift  Cut/paste/undo move engine
    AppleScriptRunner.swift  Serialized AppleScript execution
    Bluetooth.swift       BT-off-on-sleep (private IOBluetooth API)
    KeepAwake.swift       caffeinate wrapper
  Extension/         FinderSync extension (right-click menu items)
  Shared/            Code compiled into both the app and the tests
Tests/               Unit tests, run by build.sh before every build
build.sh             Full build pipeline (see above)
release.sh           Release automation
VERSION              Single source of truth for the app version
```

## License

MIT — see [LICENSE](LICENSE).

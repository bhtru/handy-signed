# Testing Strategy, Test Suite & QA Protocols

This document outlines the testing architecture, unit test harness, continuous integration setup, and manual QA protocols for **Handy**.

---

## 1. Testing Architecture & Test Harness

Handy uses a lightweight, standalone Swift unit test harness in [Tests/main.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Tests/main.swift). 

Rather than relying on `XCTest` or Xcode testing targets, the test binary is compiled directly with `swiftc` alongside production shared source files ([Sources/Shared/FileNaming.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/Shared/FileNaming.swift)). This ensures that unit tests exercise real production logic without mock drift or Xcode project dependencies.

```text
[Sources/Shared/FileNaming.swift] ──┐
                                    ├──> swiftc ──> /tmp/handy-tests-$$ ──> Execution
[Tests/main.swift] ─────────────────┘
```

---

## 2. Running Tests

### 2.1 Fast Check Command (Type-Check + Unit Tests)
```bash
bash build.sh --check
```
*This command runs in seconds and is executed automatically in CI.*

### 2.2 Standard Build Command
```bash
bash build.sh
```
*Phase 2 of `build.sh` automatically compiles and executes unit tests before assembling the app bundle or packaging the DMG installer.*

---

## 3. Unit Test Suites & Coverage

The test suite covers critical core logic, file collision resolution algorithms, status string parsing, and hardware virtual key code mappings:

### 3.1 File Conflict Naming Suite ([FileNaming.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/Shared/FileNaming.swift))
- **No Conflict**: Verifies that `report.pdf` remains `report.pdf` when no file with the same name exists in destination.
- **Single Conflict**: Verifies `report.pdf` becomes `report (2).pdf`.
- **Multiple Conflicts**: Verifies sequential incrementing (`report (3).pdf`, `report (4).pdf`).
- **Files Without Extension**: Verifies `README` becomes `README (2)`.
- **Dotfiles**: Verifies hidden files like `.gitignore` are preserved correctly.

### 3.2 Extension Status Parsing Suite ([SettingsView.swift](file:///Users/brandontruong/Documents/Personal/handy-signed/Sources/App/SettingsView.swift))
- Parses output from macOS `pluginkit -m -i com.lonfeng.handy.extension`:
  - `+` prefix → `.active`
  - `-` prefix → `.disabled`
  - Empty output inside `/Applications/` → `.registering`
  - Empty output outside `/Applications/` → `.missing`

### 3.3 Hardware Virtual Key Code Verification
- Protects physical macOS key code constants against accidental refactoring:
  - `Cmd+X` (Keycode `7`)
  - `Cmd+V` (Keycode `9`)
  - `Cmd+C` (Keycode `8`)
  - `Cmd+Z` (Keycode `6`)
  - `Return` (Keycode `36`)
  - `Escape` (Keycode `53`)

---

## 4. Continuous Integration (CI) Setup

CI is powered by GitHub Actions in [.github/workflows/ci.yml](file:///Users/brandontruong/Documents/Personal/handy-signed/.github/workflows/ci.yml).

### CI Configuration
- **Trigger**: Every push to `main` and all Pull Requests.
- **Runner**: `macos-latest`
- **Execution Step**: `bash build.sh --check`

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  check:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Type-check and run unit tests
        run: bash build.sh --check
```

---

## 5. Manual QA & Verification Protocol

Because macOS Finder extensions, accessibility event taps, and TCC security prompts interact directly with system APIs, manual QA must be conducted prior to cutting a signed release:

### Manual QA Checklist
1. **Installer DMG Verification**:
   - Mount `Handy.dmg` and drag `Handy.app` to `/Applications`.
2. **First Launch Walkthrough**:
   - Confirm settings window automatically opens on first launch.
   - Test "Start at Login" prompt dialog.
3. **Accessibility Permission Grant**:
   - Click "Grant Access" in Settings. Verify macOS System Settings opens to Accessibility.
   - Enable Handy. Verify green checkmark indicator updates within 1.5 seconds.
4. **Finder Cut & Paste Verification**:
   - Select file, press `⌘X`. Verify status indicator/sound or pending state.
   - Navigate to new folder, press `⌘V`. Verify file moved successfully.
   - Press `⌘Z`. Verify file is restored to original directory.
5. **Open with Return & Rename Guard**:
   - Press `Return` on a file. Verify file opens in default viewer.
   - Click file name to enter inline rename mode in Finder. Press `Return`. Verify text edit commits without opening the file.
6. **Finder Right-Click Extension**:
   - Right-click any file → **Copy Path**. Verify path is copied to clipboard.
   - Right-click folder → **Open in Terminal**. Verify terminal window opens in folder path.
   - Right-click empty folder space → **New .txt File Here**. Verify `Untitled.txt` is created.
   - Right-click `.zip` file → **Extract All Here**. Verify archive contents extract cleanly without `__MACOSX` folders.
7. **System Maintenance**:
   - Open Tools tab → Click **Empty Trash**. Confirm Finder confirmation dialog pops up and empties trash.

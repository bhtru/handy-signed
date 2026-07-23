# Handy User Documentation & Operations Guide

Welcome to **Handy**! Handy is a lightweight macOS menu-bar utility that brings essential Finder conveniences and system power tools right to your fingertips.

---

## 1. System Requirements & Installation

### Requirements
- **Operating System**: macOS 13.0 (Ventura) or later.
- **Location**: Must be installed in `/Applications/Handy.app`.

### Installation Steps
1. Download the latest `Handy.dmg` installer from [GitHub Releases](https://github.com/IsaacYeung/Handy/releases/latest).
2. Open `Handy.dmg` and drag **Handy** into your **Applications** folder.
3. Open **Handy** from your Applications folder.
4. The **Handy Settings** window opens automatically on first launch to guide you through initial setup.

---

## 2. Setting Up Permissions

Handy relies on three macOS permissions to deliver its seamless experience:

```text
┌─────────────────────────┐     ┌─────────────────────────┐     ┌─────────────────────────┐
│    Finder Extension     │     │      Accessibility      │     │    Finder Automation    │
│  (Right-click options)  │     │   (Keyboard shortcuts)  │     │    (File move & open)   │
└─────────────────────────┘     └─────────────────────────┘     └─────────────────────────┘
```

| Permission | What It Enables | How to Grant |
|---|---|---|
| **Finder Extension** | Right-click context menu options (*Copy Path*, *Open in Terminal*, *New .txt File*, *Extract All*) | Open **System Settings** → **General** → **Login Items & Extensions** → **Finder Extensions** → enable **Handy Extension**. |
| **Accessibility** | Global `⌘X`/`⌘V`/`⌘Z`/`Return` shortcut interception | In Handy Settings **General** tab, click **Grant Access**. Toggle Handy **ON** in the Accessibility window that appears. |
| **Automation** | Interacting with Finder to fetch selected files and empty trash | Click **Allow** when macOS prompts *"Handy wants to control Finder"* on first use. |

> [!TIP]
> **Updating or Permission Reset**: If a keyboard shortcut ever stops responding, simply go to Handy's **General** tab and click **Grant Access** again. Handy automatically clears stale permission entries and walks you through re-enabling.

---

## 3. Feature User Guide

### 3.1 Cut & Paste Files (`⌘X` / `⌘V` / `⌘Z`)
- **Cut (`⌘X`)**: Select one or more files in Finder and press `⌘X`. The items are staged for relocation.
- **Paste (`⌘V`)**: Open the target folder in Finder and press `⌘V`. Handy moves the files immediately.
  - *Conflict Resolution*: If a file with the same name already exists in the target folder, Handy renames the moved file automatically (e.g. `Invoice (2).pdf`), preventing accidental overwrites.
- **Undo (`⌘Z`)**: Press `⌘Z` to undo the move and return files to their original location.
- **Cancel Cut (`Esc` / `⌘C`)**: Press `Esc` or `⌘C` to cancel a cut selection without moving any files.

### 3.2 Open Files with Return
- Highlight any file or folder in Finder and press `Return` to open it immediately.
- **Renaming Files**: Handy automatically detects when you are renaming a file. Pressing `Return` while editing a filename will save the new name as expected without opening the file. You can also press `Shift+Return` to start renaming.

### 3.3 Right-Click Context Menu Options
Right-click items inside any Finder window to use Handy's context menu actions:
- **Copy Path**: Instantly copies the full file path to your clipboard.
- **Open in Terminal**: Opens the current directory in your terminal. Automatically uses **iTerm2** if installed, or default **Terminal**.
- **New .txt File Here**: Right-click in empty folder space to create a blank `Untitled.txt` document.
- **Extract All Here**: Right-click a `.zip` file to extract its contents without creating unwanted `__MACOSX` junk folders.

### 3.4 System Power & Utility Tweaks
Accessible from the **Tweaks** tab in Handy Settings or the menu bar:
- **Keep Awake**: Keeps your Mac's screen and system awake (useful during long downloads or presentations).
- **Bluetooth Off on Sleep**: Automatically powers down Bluetooth radio when your Mac sleeps, saving battery, and restores it when you wake your Mac.
- **Show Hidden Files**: Quickly toggles visibility of hidden dotfiles (`.gitignore`, `.ds_store`, etc.) in Finder.
- **Toggle Dark Mode**: Switches system appearance between Dark and Light mode.
- **Empty Trash**: Located in the **Tools** tab; empties Finder trash safely across all internal and external drives.

---

## 4. Updates

Handy automatically checks for updates using EdDSA cryptographically signed update feeds from GitHub Releases. 
- You can manually check for updates anytime by clicking the **H** icon in your Mac's menu bar and selecting **Check for Updates…**.

---

## 5. Frequently Asked Questions & Troubleshooting

#### Q: Why is "Handy Extension" showing as missing or disabled?
**A**: Make sure `Handy.app` is placed directly in `/Applications`. Extensions located in `/Downloads` or `Desktop` cannot be properly registered by macOS `pluginkit`.

#### Q: `⌘X` plays an alert beep or doesn't cut files.
**A**: Ensure Accessibility and Finder Automation permissions are granted:
1. Open Handy Settings → **General** tab.
2. Verify Accessibility shows green **Granted**. If orange, click **Grant Access**.
3. Verify Finder automation status in **Tweaks** tab shows green **granted**.

#### Q: How do I remove Handy?
**A**: Quit Handy from the menu bar, turn off Launch at Login in Settings, and drag `Handy.app` from `/Applications` to the Trash.

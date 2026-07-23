import Cocoa
import SwiftUI
import ServiceManagement
import Sparkle

private func makeHandyStatusIcon() -> NSImage {
    let image = NSImage(size: NSSize(width: 18, height: 18))
    image.lockFocus()

    let frame = NSBezierPath(
        roundedRect: NSRect(x: 1.25, y: 1.25, width: 15.5, height: 15.5),
        xRadius: 3.2,
        yRadius: 3.2
    )
    frame.lineWidth = 1.5
    NSColor.black.setStroke()
    frame.stroke()

    // Caslonian's italic capital H, reduced to a crisp single-colour menu-bar mark.
    if let context = NSGraphicsContext.current?.cgContext {
        let mark = CGMutablePath()
        mark.move(to: CGPoint(x: 522, y: 661))
        mark.addCurve(to: CGPoint(x: 589, y: 586), control1: CGPoint(x: 595, y: 657), control2: CGPoint(x: 611, y: 652))
        mark.addLine(to: CGPoint(x: 512, y: 350))
        mark.addLine(to: CGPoint(x: 218, y: 350))
        mark.addLine(to: CGPoint(x: 294, y: 586))
        mark.addCurve(to: CGPoint(x: 392, y: 661), control1: CGPoint(x: 314, y: 646), control2: CGPoint(x: 326, y: 657))
        mark.addLine(to: CGPoint(x: 396, y: 675))
        mark.addLine(to: CGPoint(x: 130, y: 675))
        mark.addLine(to: CGPoint(x: 125, y: 661))
        mark.addCurve(to: CGPoint(x: 192, y: 586), control1: CGPoint(x: 197, y: 657), control2: CGPoint(x: 214, y: 652))
        mark.addLine(to: CGPoint(x: 30, y: 89))
        mark.addCurve(to: CGPoint(x: -67, y: 14), control1: CGPoint(x: 11, y: 29), control2: CGPoint(x: -1, y: 18))
        mark.addLine(to: CGPoint(x: -71, y: 0))
        mark.addLine(to: CGPoint(x: 195, y: 0))
        mark.addLine(to: CGPoint(x: 199, y: 14))
        mark.addCurve(to: CGPoint(x: 133, y: 89), control1: CGPoint(x: 127, y: 18), control2: CGPoint(x: 111, y: 23))
        mark.addLine(to: CGPoint(x: 213, y: 336))
        mark.addLine(to: CGPoint(x: 508, y: 336))
        mark.addLine(to: CGPoint(x: 427, y: 89))
        mark.addCurve(to: CGPoint(x: 330, y: 14), control1: CGPoint(x: 408, y: 29), control2: CGPoint(x: 396, y: 18))
        mark.addLine(to: CGPoint(x: 326, y: 0))
        mark.addLine(to: CGPoint(x: 592, y: 0))
        mark.addLine(to: CGPoint(x: 596, y: 14))
        mark.addCurve(to: CGPoint(x: 530, y: 89), control1: CGPoint(x: 524, y: 18), control2: CGPoint(x: 508, y: 23))
        mark.addLine(to: CGPoint(x: 691, y: 586))
        mark.addCurve(to: CGPoint(x: 788, y: 661), control1: CGPoint(x: 711, y: 646), control2: CGPoint(x: 722, y: 657))
        mark.addLine(to: CGPoint(x: 793, y: 675))
        mark.addLine(to: CGPoint(x: 527, y: 675))
        mark.closeSubpath()

        context.saveGState()
        context.translateBy(x: 2.4, y: 3.4)
        context.scaleBy(x: 0.0165, y: 0.0165)
        context.addPath(mark)
        context.setFillColor(NSColor.black.cgColor)
        context.fillPath()
        context.restoreGState()
    }

    image.unlockFocus()
    image.isTemplate = true
    return image
}

// MARK: - Settings window

class SettingsWindowController: NSWindowController, NSWindowDelegate {
    static let shared = SettingsWindowController()

    private init() {
        let hosting = NSHostingController(rootView: SettingsView())
        let win = NSWindow(contentViewController: hosting)
        win.title = "Handy"
        win.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
        win.titlebarAppearsTransparent = true
        win.center()
        win.isReleasedWhenClosed = false
        super.init(window: win)
        win.delegate = self
    }

    required init?(coder: NSCoder) { fatalError() }

    func show() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        DispatchQueue.main.async { NSApp.setActivationPolicy(.accessory) }
    }
}

// MARK: - App delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    private var cutBadgeItem: NSMenuItem?

    // Sparkle auto-updater. Checks the appcast on GitHub Releases on a
    // schedule and via the "Check for Updates…" menu item.
    let updaterController = SPUStandardUpdaterController(
        startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NSApp.appearance = nil
        setupStatusBar()
        observeSystemAppearance()

        let cutPaste     = UserDefaults.standard.bool(forKey: "kb.cutPaste")
        let returnToOpen = UserDefaults.standard.bool(forKey: "kb.returnToOpen")
        if cutPaste || returnToOpen { EventTap.shared.startIfPermitted() }
        BluetoothSleepFeature.shared.startIfEnabled()

        // Persistent watchdog: restarts the event tap if permission is granted
        // but the tap failed to start (race at launch) or was disabled by macOS.
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            let needs = UserDefaults.standard.bool(forKey: "kb.cutPaste")
                     || UserDefaults.standard.bool(forKey: "kb.returnToOpen")
            if needs { EventTap.shared.startIfPermitted() }
        }

        NotificationCenter.default.addObserver(
            self, selector: #selector(cutStateChanged(_:)),
            name: .cutPasteStateChanged, object: nil)

        let isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            performFirstLaunchSetup()
        } else {
            checkAndShowSettingsIfNeeded()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Kill the caffeinate child — otherwise it outlives Handy and the
        // Mac never sleeps again until the orphan is killed manually.
        KeepAwake.shared.disable()
        // If we quit between sleep and wake, put Bluetooth back on.
        BluetoothSleepFeature.shared.restoreOnQuit()
        EventTap.shared.stop()
    }

    // MARK: First launch

    private func performFirstLaunchSetup() {
        DispatchQueue.global(qos: .userInitiated).async {
            forceRegisterExtension()
            let enable = Process()
            enable.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
            enable.arguments = ["-e", "use", "-i", "com.lonfeng.handy.extension"]
            enable.standardOutput = Pipe(); enable.standardError = Pipe()
            try? enable.run(); enable.waitUntilExit()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.askAboutLoginItem()
                SettingsWindowController.shared.show()
            }
        }
    }

    private func askAboutLoginItem() {
        let alert = NSAlert()
        alert.messageText = "Keep Handy running at login?"
        alert.informativeText = "Handy will sit in your menu bar and be ready whenever you need it."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Yes, Start at Login")
        alert.addButton(withTitle: "Not Now")
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            try? SMAppService.mainApp.register()
        }
    }

    private func checkAndShowSettingsIfNeeded() {
        DispatchQueue.global(qos: .background).async {
            forceRegisterExtension()
            let out = pluginkitQuery()
            if !out.contains("+") {
                DispatchQueue.main.async { SettingsWindowController.shared.show() }
            }
        }
    }

    // MARK: Menu bar

    private func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusBarItem?.button {
            button.image = makeHandyStatusIcon()
            button.image?.accessibilityDescription = "Handy"
        }

        let menu = NSMenu()

        // Cut badge — shown when files are pending move
        let badge = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        badge.isHidden = true; badge.isEnabled = false
        cutBadgeItem = badge
        menu.addItem(badge)
        menu.addItem(.separator())

        menu.addItem(NSMenuItem(title: "Settings\u{2026}",
                                action: #selector(openSettings), keyEquivalent: ","))

        // Target the updater controller directly — it also handles
        // enabling/disabling the item while a check is in progress.
        let updateItem = NSMenuItem(
            title: "Check for Updates\u{2026}",
            action: #selector(SPUStandardUpdaterController.checkForUpdates(_:)),
            keyEquivalent: "")
        updateItem.target = updaterController
        menu.addItem(updateItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Handy",
                                action: #selector(quit), keyEquivalent: "q"))
        statusBarItem?.menu = menu
    }

    // MARK: Cut badge

    @objc private func cutStateChanged(_ notification: Notification) {
        guard let count = notification.object as? Int else { return }
        if count > 0 {
            let noun = count == 1 ? "file" : "files"
            cutBadgeItem?.title    = "\u{2702}\u{FE0E} \(count) \(noun) ready to move \u{2014} \u{2318}V to paste"
            cutBadgeItem?.isHidden = false
        } else {
            cutBadgeItem?.title    = ""
            cutBadgeItem?.isHidden = true
        }
    }

    // MARK: Appearance

    private func observeSystemAppearance() {
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(systemAppearanceChanged),
            name: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil)
    }

    @objc private func systemAppearanceChanged() { NSApp.appearance = nil }

    // MARK: General actions

    @objc func openSettings() { SettingsWindowController.shared.show() }
    @objc func quit()         { NSApp.terminate(nil) }
}

// MARK: - Shared helpers

func forceRegisterExtension() {
    let extPath = Bundle.main.bundleURL
        .appendingPathComponent("Contents/PlugIns/Handy Extension.appex")
    guard FileManager.default.fileExists(atPath: extPath.path) else { return }
    let t = Process()
    t.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
    t.arguments = ["-v", "-a", extPath.path]
    t.standardOutput = Pipe(); t.standardError = Pipe()
    try? t.run(); t.waitUntilExit()
}

// MARK: - Entry point

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

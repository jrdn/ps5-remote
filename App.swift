import AppKit
import IOKit.hid
import ServiceManagement

let logPath = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("Library/Logs/PS5 Remote.log").path

class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let connectionItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let accessibilityItem = NSMenuItem(title: "⚠️ Accessibility not granted — can't send keys", action: nil, keyEquivalent: "")
    private let inputMonitoringItem = NSMenuItem(title: "⚠️ Input Monitoring not granted — restart after granting", action: nil, keyEquivalent: "")
    private let loginItem = NSMenuItem(title: "Launch at Login", action: nil, keyEquivalent: "")
    private let configPath: String
    private var connected = false

    init(configPath: String) {
        self.configPath = configPath
        super.init()

        accessibilityItem.action = #selector(openAccessibilitySettings)
        accessibilityItem.target = self
        inputMonitoringItem.action = #selector(openInputMonitoringSettings)
        inputMonitoringItem.target = self
        loginItem.action = #selector(toggleLaunchAtLogin)
        loginItem.target = self

        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(connectionItem)
        menu.addItem(accessibilityItem)
        menu.addItem(inputMonitoringItem)
        menu.addItem(.separator())
        menu.addItem(item("Reload Config", #selector(reloadConfig), "r"))
        menu.addItem(item("Open Config", #selector(openConfig), "o"))
        // Output only goes to the log file when not launched from a terminal
        if isatty(STDOUT_FILENO) == 0 {
            menu.addItem(item("Open Log", #selector(openLog), "l"))
        }
        // Login items need a real app bundle
        if Bundle.main.bundleIdentifier != nil {
            menu.addItem(.separator())
            menu.addItem(loginItem)
        }
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit PS5 Remote", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
        statusItem.menu = menu

        // Ask for Accessibility up front; posting key events fails silently without it
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)

        // Permissions can be granted while running, so keep the icon current
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in self?.refresh() }
        refresh()
    }

    private func item(_ title: String, _ action: Selector, _ key: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    func setConnected(_ connected: Bool) {
        self.connected = connected
        refresh()
    }

    private func refresh() {
        let hasAccessibility = AXIsProcessTrusted()
        let hasInputMonitoring = IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) == kIOHIDAccessTypeGranted
        accessibilityItem.isHidden = hasAccessibility
        inputMonitoringItem.isHidden = hasInputMonitoring

        let symbol = !(hasAccessibility && hasInputMonitoring) ? "exclamationmark.triangle"
            : connected ? "gamecontroller.fill" : "gamecontroller"
        statusItem.button?.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "PS5 Remote")
        connectionItem.title = connected ? "Controller connected" : "Waiting for controller…"
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    func menuWillOpen(_ menu: NSMenu) {
        refresh()
    }

    @objc func reloadConfig() {
        do {
            bindings = try loadBindings(path: configPath)
            print("Loaded bindings from \(configPath)", to: &standardError)
        } catch {
            print("Config error: \(error)", to: &standardError)
            showAlert("Could not load bindings", "\(error)")
        }
    }

    @objc func openConfig() {
        NSWorkspace.shared.open(URL(fileURLWithPath: configPath))
    }

    @objc func openLog() {
        NSWorkspace.shared.open(URL(fileURLWithPath: logPath))
    }

    @objc func openAccessibilitySettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }

    @objc func openInputMonitoringSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!)
    }

    @objc func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            showAlert("Could not change login item", error.localizedDescription)
        }
        refresh()
    }

    private func showAlert(_ title: String, _ message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}

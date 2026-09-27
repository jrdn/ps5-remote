import Foundation
import CoreGraphics
import AppKit

typealias Action = () -> Void

class Actions {
    static func logEvent(_ message: String) {
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        print("[\(timestamp)] ACTION: \(message)")
    }

    static func getActiveAppBundleId() -> String? {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    static func getActiveAppName() -> String? {
        NSWorkspace.shared.frontmostApplication?.localizedName
    }

    static func isActiveApp(_ bundleId: String) -> Bool {
        getActiveAppBundleId()?.localizedCaseInsensitiveContains(bundleId) ?? false
    }

    // MARK: - Key Events

    // Some shortcuts (space switching, dictation, Lightroom keys) only register via System Events
    static func appleScriptKey(_ keyCode: CGKeyCode, flags: CGEventFlags = []) {
        var mods: [String] = []
        if flags.contains(.maskCommand)   { mods.append("command down") }
        if flags.contains(.maskShift)     { mods.append("shift down") }
        if flags.contains(.maskAlternate) { mods.append("option down") }
        if flags.contains(.maskControl)   { mods.append("control down") }
        let using = mods.isEmpty ? "" : " using {\(mods.joined(separator: ", "))}"
        runAppleScript("""
        tell application "System Events"
            key code \(keyCode)\(using)
        end tell
        """)
    }

    static func cmdBracketLeft() {
        logEvent("\(getActiveAppName() ?? "unknown"): Cmd+[")
        postKey(33, flags: .maskCommand)
    }

    static func cmdBracketRight() {
        logEvent("\(getActiveAppName() ?? "unknown"): Cmd+]")
        postKey(30, flags: .maskCommand)
    }


    // MARK: - iTerm2

    static func iterm2NextTab() {
        logEvent("\(getActiveAppName() ?? "unknown"): Cmd+Shift+] (next tab)")
        postKey(30, flags: [.maskCommand, .maskShift])
    }

    static func iterm2PrevTab() {
        logEvent("\(getActiveAppName() ?? "unknown"): Cmd+Shift+[ (prev tab)")
        postKey(33, flags: [.maskCommand, .maskShift])
    }

    // MARK: - System Actions (require AppleScript or Shortcuts)

    // Set at startup by checkVoiceControlShortcuts()
    static var voiceControlShortcutsAvailable = false

    static func checkVoiceControlShortcuts() {
        let task = Process()
        task.launchPath = "/usr/bin/shortcuts"
        task.arguments = ["list"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()  // suppress shortcuts CLI noise
        task.launch()
        task.waitUntilExit()

        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let names = Set(output.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) })
        voiceControlShortcutsAvailable = names.contains("VoiceControl On") && names.contains("VoiceControl Off")

        if !voiceControlShortcutsAvailable {
            FileHandle.standardError.write(Data("""
            [WARNING] Shortcuts 'VoiceControl On' / 'VoiceControl Off' not found.
                      Falling back to fragile Siri-based toggle.
                      To use the reliable method, create both shortcuts in Shortcuts.app.\n
            """.utf8))
        }
    }

    static func toggleMissionControl() {
        logEvent("Toggling Mission Control")
        runAppleScript("""
        tell application "Mission Control"
            activate
        end tell
        """)
    }

    static func toggleVoiceControl() {
        let check = Process()
        check.launchPath = "/usr/bin/defaults"
        check.arguments = ["read", "com.apple.Accessibility", "CommandAndControlEnabled"]
        let pipe = Pipe()
        check.standardOutput = pipe
        check.launch()
        check.waitUntilExit()

        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let isEnabled = output.trimmingCharacters(in: .whitespacesAndNewlines) == "1"

        if voiceControlShortcutsAvailable {
            let shortcutName = isEnabled ? "VoiceControl Off" : "VoiceControl On"
            logEvent("Running shortcut: \(shortcutName)")
            let task = Process()
            task.launchPath = "/usr/bin/shortcuts"
            task.arguments = ["run", shortcutName]
            task.launch()
        } else {
            let command = isEnabled ? "turn off voice control" : "turn on voice control"
            logEvent("Asking Siri to \(command) (fallback)")
            runAppleScript("""
            tell application "System Events"
                tell process "SystemUIServer"
                    click (first menu bar item of menu bar 1 whose description contains "Siri")
                end tell
            end tell
            delay 0.5
            tell application "System Events"
                tell process "Siri"
                    keystroke "\(command)"
                    delay 0.2
                    key code 36
                    delay 1.2
                    key code 53
                end tell
            end tell
            """)
        }
    }

    // MARK: - Mouse Clicks

    static func middleClick() {
        logEvent("Middle click")
        guard let currentEvent = CGEvent(source: nil) else { return }
        let pos = currentEvent.location

        guard let downEvent = CGEvent(mouseEventSource: nil, mouseType: .otherMouseDown,
                                      mouseCursorPosition: pos, mouseButton: .center),
              let upEvent = CGEvent(mouseEventSource: nil, mouseType: .otherMouseUp,
                                    mouseCursorPosition: pos, mouseButton: .center) else { return }

        downEvent.post(tap: .cghidEventTap)
        usleep(10000)
        upEvent.post(tap: .cghidEventTap)
    }

    static func leftClick() {
        logEvent("Left click")
        guard let currentEvent = CGEvent(source: nil) else { return }
        let pos = currentEvent.location

        guard let downEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown,
                                      mouseCursorPosition: pos, mouseButton: .left),
              let upEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp,
                                    mouseCursorPosition: pos, mouseButton: .left) else { return }

        downEvent.post(tap: .cghidEventTap)
        usleep(10000)
        upEvent.post(tap: .cghidEventTap)
    }

    static func leftClickDown() {
        logEvent("Left click: down (drag start)")
        guard let currentEvent = CGEvent(source: nil) else { return }
        let pos = currentEvent.location

        guard let downEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown,
                                      mouseCursorPosition: pos, mouseButton: .left) else { return }
        downEvent.post(tap: .cghidEventTap)
    }

    static func leftClickUp() {
        logEvent("Left click: up (drag end)")
        guard let currentEvent = CGEvent(source: nil) else { return }
        let pos = currentEvent.location

        guard let upEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp,
                                    mouseCursorPosition: pos, mouseButton: .left) else { return }
        upEvent.post(tap: .cghidEventTap)
    }

    static func rightClick() {
        logEvent("Right click")
        guard let currentEvent = CGEvent(source: nil) else { return }
        let pos = currentEvent.location

        guard let downEvent = CGEvent(mouseEventSource: nil, mouseType: .rightMouseDown,
                                      mouseCursorPosition: pos, mouseButton: .right),
              let upEvent = CGEvent(mouseEventSource: nil, mouseType: .rightMouseUp,
                                    mouseCursorPosition: pos, mouseButton: .right) else { return }

        downEvent.post(tap: .cghidEventTap)
        usleep(10000)
        upEvent.post(tap: .cghidEventTap)
    }

    // MARK: - Stick-to-Mouse/Scroll

    private static let MOUSE_SENSITIVITY: Double = 0.5
    // Max lines per event at full stick deflection (runs at 60Hz, cubic curve)
    private static let SCROLL_MAX_LINES: Double = 5.0
    private static var scrollAccumX: Double = 0
    private static var scrollAccumY: Double = 0

    private static func stickCurve(_ raw: Int) -> Double {
        let norm = Double(raw - 128) / 128.0
        return norm * abs(norm) * 128.0 * MOUSE_SENSITIVITY
    }

    static func moveMouseByStick(x: Int, y: Int) {
        let deltaX = stickCurve(x)
        let deltaY = stickCurve(y)
        if abs(deltaX) < 0.5 && abs(deltaY) < 0.5 { return }

        guard let currentEvent = CGEvent(source: nil) else { return }
        let currentPos = currentEvent.location
        let newPos = CGPoint(x: currentPos.x + deltaX, y: currentPos.y + deltaY)

        guard let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved,
                                      mouseCursorPosition: newPos, mouseButton: .left) else { return }
        moveEvent.post(tap: .cghidEventTap)
    }

    static func scrollByStick(x: Int, y: Int) {
        let normY = Double(y - 128) / 127.0
        let normX = Double(x - 128) / 127.0

        // Cubic acceleration: small deflections are very gentle, large deflections are fast
        scrollAccumY += -(normY * normY * normY) * SCROLL_MAX_LINES
        scrollAccumX += -(normX * normX * normX) * SCROLL_MAX_LINES

        let scrollY = Int32(scrollAccumY)
        let scrollX = Int32(scrollAccumX)
        scrollAccumY -= Double(scrollY)
        scrollAccumX -= Double(scrollX)

        if scrollY == 0 && scrollX == 0 { return }

        guard let scrollEvent = CGEvent(scrollWheelEvent2Source: nil,
                                       units: .pixel,
                                       wheelCount: 2,
                                       wheel1: scrollY,
                                       wheel2: scrollX,
                                       wheel3: 0) else { return }
        scrollEvent.post(tap: .cghidEventTap)
    }

    // MARK: - Helpers

    static func postKey(_ keyCode: CGKeyCode, flags: CGEventFlags = []) {
        let src = CGEventSource(stateID: .hidSystemState)
        guard let down = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: false) else { return }
        let mods = modifierKeyCodes(for: flags)
        if !flags.isEmpty {
            down.flags = down.flags.union(flags)
            up.flags = up.flags.union(flags)
        }
        for mod in mods {
            guard let e = CGEvent(keyboardEventSource: src, virtualKey: mod, keyDown: true) else { continue }
            e.flags = e.flags.union(flags)
            e.post(tap: .cghidEventTap)
        }
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
        for mod in mods.reversed() {
            guard let e = CGEvent(keyboardEventSource: src, virtualKey: mod, keyDown: false) else { continue }
            e.post(tap: .cghidEventTap)
        }
    }

    private static func modifierKeyCodes(for flags: CGEventFlags) -> [CGKeyCode] {
        var keys: [CGKeyCode] = []
        if flags.contains(.maskCommand)  { keys.append(55) }
        if flags.contains(.maskShift)    { keys.append(56) }
        if flags.contains(.maskAlternate){ keys.append(58) }
        if flags.contains(.maskControl)  { keys.append(59) }
        return keys
    }

    static func postKeyDown(_ keyCode: CGKeyCode, flags: CGEventFlags = []) {
        let src = CGEventSource(stateID: .hidSystemState)
        for mod in modifierKeyCodes(for: flags) {
            guard let e = CGEvent(keyboardEventSource: src, virtualKey: mod, keyDown: true) else { continue }
            e.flags = e.flags.union(flags)
            e.post(tap: .cghidEventTap)
        }
        guard let down = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: true) else { return }
        if !flags.isEmpty { down.flags = down.flags.union(flags) }
        down.post(tap: .cghidEventTap)
    }

    static func postKeyUp(_ keyCode: CGKeyCode, flags: CGEventFlags = []) {
        let src = CGEventSource(stateID: .hidSystemState)
        guard let up = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: false) else { return }
        if !flags.isEmpty { up.flags = up.flags.union(flags) }
        up.post(tap: .cghidEventTap)
        for mod in modifierKeyCodes(for: flags).reversed() {
            guard let e = CGEvent(keyboardEventSource: src, virtualKey: mod, keyDown: false) else { continue }
            e.post(tap: .cghidEventTap)
        }
    }

    private static func runAppleScript(_ script: String) {
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        task.launch()
    }
}

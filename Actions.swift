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
        getActiveAppBundleId()?.contains(bundleId) ?? false
    }

    static func isActiveBrowser() -> Bool {
        isActiveApp("firefox") || isActiveApp("Chrome") || isActiveApp("Safari")
    }

    // MARK: - Space / Window Management

    static func switchSpaceLeft() {
        logEvent("Switching space left (Ctrl+Left)")
        runAppleScript("""
        tell application "System Events"
            key code 123 using control down
        end tell
        """)
    }

    static func switchSpaceRight() {
        logEvent("Switching space right (Ctrl+Right)")
        runAppleScript("""
        tell application "System Events"
            key code 124 using control down
        end tell
        """)
    }

    // MARK: - Key Events

    static func sendEscape() { postKey(53) }
    static func sendEnter()  { postKey(36) }

    static func startDictationPress() {
        logEvent("Dictation: key down (L2, Cmd+Shift+Opt+F9)")
        postKeyDown(101, flags: [.maskCommand, .maskShift, .maskAlternate])
    }

    static func startDictationRelease() {
        logEvent("Dictation: key up (L2, Cmd+Shift+Opt+F9)")
        postKeyUp(101, flags: [.maskCommand, .maskShift, .maskAlternate])
    }

    static func startDictationPressPS() {
        logEvent("Dictation: toggle (PS, Cmd+Shift+Opt+F10)")
        postKey(109, flags: [.maskCommand, .maskShift, .maskAlternate])
    }

    static func arrowUp()    { postKey(126) }
    static func arrowDown()  { postKey(125) }
    static func arrowLeft()  { postKey(123) }
    static func arrowRight() { postKey(124) }

    static func shiftArrowUp() {
        logEvent("\(getActiveAppName() ?? "unknown"): Shift+Up")
        postKey(126, flags: .maskShift)
    }

    static func shiftArrowDown() {
        logEvent("\(getActiveAppName() ?? "unknown"): Shift+Down")
        postKey(125, flags: .maskShift)
    }

    static func shiftArrowLeft() {
        logEvent("\(getActiveAppName() ?? "unknown"): Shift+Left")
        postKey(123, flags: .maskShift)
    }

    static func shiftArrowRight() {
        logEvent("\(getActiveAppName() ?? "unknown"): Shift+Right")
        postKey(124, flags: .maskShift)
    }

    static func browserNextTab() {
        logEvent("\(getActiveAppName() ?? "unknown"): Cmd+Shift+] (next tab)")
        postKey(30, flags: [.maskCommand, .maskShift])
    }

    static func browserPrevTab() {
        logEvent("\(getActiveAppName() ?? "unknown"): Cmd+Shift+[ (prev tab)")
        postKey(33, flags: [.maskCommand, .maskShift])
    }

    static func closeTab() {
        logEvent("\(getActiveAppName() ?? "unknown"): Cmd+W (close tab)")
        postKey(13, flags: .maskCommand)
    }

    static func cmdBracketLeft() {
        logEvent("\(getActiveAppName() ?? "unknown"): Cmd+[")
        postKey(33, flags: .maskCommand)
    }

    static func cmdBracketRight() {
        logEvent("\(getActiveAppName() ?? "unknown"): Cmd+]")
        postKey(30, flags: .maskCommand)
    }

    static func cmdBacktick() {
        logEvent("\(getActiveAppName() ?? "unknown"): Cmd+`")
        postKey(50, flags: .maskCommand)
    }

    static func cmdShiftBacktick() {
        logEvent("\(getActiveAppName() ?? "unknown"): Cmd+Shift+`")
        postKey(50, flags: [.maskCommand, .maskShift])
    }

    static func controlTab() {
        logEvent("\(getActiveAppName() ?? "unknown"): Control+Tab")
        postKey(48, flags: .maskControl)
    }

    static func controlShiftTab() {
        logEvent("\(getActiveAppName() ?? "unknown"): Control+Shift+Tab")
        postKey(48, flags: [.maskControl, .maskShift])
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

    static func iterm2PaneLeft() {
        logEvent("\(getActiveAppName() ?? "unknown"): Cmd+Opt+Left (pane left)")
        postKey(123, flags: [.maskCommand, .maskAlternate])
    }

    static func iterm2PaneRight() {
        logEvent("\(getActiveAppName() ?? "unknown"): Cmd+Opt+Right (pane right)")
        postKey(124, flags: [.maskCommand, .maskAlternate])
    }

    static func iterm2PaneUp() {
        logEvent("\(getActiveAppName() ?? "unknown"): Cmd+Opt+Up (pane up)")
        postKey(126, flags: [.maskCommand, .maskAlternate])
    }

    static func iterm2PaneDown() {
        logEvent("\(getActiveAppName() ?? "unknown"): Cmd+Opt+Down (pane down)")
        postKey(125, flags: [.maskCommand, .maskAlternate])
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

    private static let MOUSE_SENSITIVITY: Double = 0.2
    private static let SCROLL_SENSITIVITY: Double = 0.03
    private static var scrollEventCounter = 0

    static func moveMouseByStick(x: Int, y: Int) {
        let deltaX = Double(x - 128) * MOUSE_SENSITIVITY
        let deltaY = Double(y - 128) * MOUSE_SENSITIVITY
        if abs(deltaX) < 0.5 && abs(deltaY) < 0.5 { return }

        guard let currentEvent = CGEvent(source: nil) else { return }
        let currentPos = currentEvent.location
        let newPos = CGPoint(x: currentPos.x + deltaX, y: currentPos.y + deltaY)

        guard let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved,
                                      mouseCursorPosition: newPos, mouseButton: .left) else { return }
        moveEvent.post(tap: .cghidEventTap)
    }

    static func scrollByStick(x: Int, y: Int) {
        // Throttle to 15Hz (every 4th frame) for slower, smoother scrolling
        scrollEventCounter += 1
        guard scrollEventCounter % 4 == 0 else { return }

        let scrollY = -Int32(Double(y - 128) * SCROLL_SENSITIVITY)
        let scrollX = -Int32(Double(x - 128) * SCROLL_SENSITIVITY)
        if abs(scrollY) < 1 && abs(scrollX) < 1 { return }

        guard let scrollEvent = CGEvent(scrollWheelEvent2Source: nil,
                                       units: .line,
                                       wheelCount: 2,
                                       wheel1: scrollY,
                                       wheel2: scrollX,
                                       wheel3: 0) else { return }
        scrollEvent.post(tap: .cghidEventTap)
    }

    // MARK: - Helpers

    private static func postKey(_ keyCode: CGKeyCode, flags: CGEventFlags = []) {
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

    private static func postKeyDown(_ keyCode: CGKeyCode, flags: CGEventFlags = []) {
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

    private static func postKeyUp(_ keyCode: CGKeyCode, flags: CGEventFlags = []) {
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

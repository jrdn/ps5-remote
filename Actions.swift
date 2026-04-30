import Foundation
import CoreGraphics
import AppKit

typealias Action = () -> Void

class Actions {
    static func logEvent(_ message: String) {
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        print("[\(timestamp)] ACTION: \(message)")
    }

    // Get info about the active application
    static func getActiveAppBundleId() -> String? {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    static func getActiveAppName() -> String? {
        NSWorkspace.shared.frontmostApplication?.localizedName
    }

    static func isActiveApp(_ bundleId: String) -> Bool {
        getActiveAppBundleId()?.contains(bundleId) ?? false
    }

    static func osascriptKey(_ keyCombo: String) {
        let script = """
        tell application "System Events"
            key code \(keyCombo)
        end tell
        """

        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        task.launch()
    }

    static func typeString(_ text: String) {
        for char in text {
            if let keyCode = charToKeyCode(char) {
                osascriptKey(String(keyCode))
            }
        }
    }

    static func systemCommand(_ command: String) {
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", command]
        task.launch()
    }

    // macOS-specific actions using AppleScript (more reliable)
    static func switchSpaceLeft() {
        logEvent("Switching space left (Ctrl+Left)")
        let script = """
        tell application "System Events"
            key code 123 using control down
        end tell
        """
        runAppleScript(script)
    }

    static func switchSpaceRight() {
        logEvent("Switching space right (Ctrl+Right)")
        let script = """
        tell application "System Events"
            key code 124 using control down
        end tell
        """
        runAppleScript(script)
    }

    static func toggleMissionControl() {
        logEvent("Toggling Mission Control")
        let script = """
        tell application "Mission Control"
            activate
        end tell
        """
        runAppleScript(script)
    }

    static func sendKeyWithModifier(_ keyCode: Int, modifier: String) {
        let script = """
        tell application "System Events"
            key code \(keyCode) using \(modifier) down
        end tell
        """
        runAppleScript(script)
    }

    static func shiftArrowUp() {
        logEvent("\(getActiveAppName() ?? "unknown"): Shift+Up")
        sendKeyWithModifier(126, modifier: "shift")  // Up arrow = 126
    }

    static func shiftArrowDown() {
        logEvent("\(getActiveAppName() ?? "unknown"): Shift+Down")
        sendKeyWithModifier(125, modifier: "shift")  // Down arrow = 125
    }

    static func shiftArrowLeft() {
        logEvent("\(getActiveAppName() ?? "unknown"): Shift+Left")
        sendKeyWithModifier(123, modifier: "shift")  // Left arrow = 123
    }

    static func shiftArrowRight() {
        logEvent("\(getActiveAppName() ?? "unknown"): Shift+Right")
        sendKeyWithModifier(124, modifier: "shift")  // Right arrow = 124
    }

    static func cmdBacktick() {
        logEvent("\(getActiveAppName() ?? "unknown"): Cmd+`")
        let script = """
        tell application "System Events"
            key code 50 using command down
        end tell
        """
        runAppleScript(script)
    }

    static func cmdShiftBacktick() {
        logEvent("\(getActiveAppName() ?? "unknown"): Cmd+Shift+`")
        let script = """
        tell application "System Events"
            key code 50 using {command down, shift down}
        end tell
        """
        runAppleScript(script)
    }

    static func controlTab() {
        logEvent("\(getActiveAppName() ?? "unknown"): Control+Tab")
        let script = """
        tell application "System Events"
            key code 48 using control down
        end tell
        """
        runAppleScript(script)
    }

    static func controlShiftTab() {
        logEvent("\(getActiveAppName() ?? "unknown"): Control+Shift+Tab")
        let script = """
        tell application "System Events"
            key code 48 using {control down, shift down}
        end tell
        """
        runAppleScript(script)
    }

    // Stick-to-mouse conversion
    private static let MOUSE_SENSITIVITY: Double = 0.2
    private static let SCROLL_SENSITIVITY: Double = 0.05

    static func moveMouseByStick(x: Int, y: Int) {
        // Convert 0-255 to delta (-128 to 127)
        let deltaX = Double(x - 128) * MOUSE_SENSITIVITY
        let deltaY = Double(y - 128) * MOUSE_SENSITIVITY

        // Skip if movement is negligible
        if abs(deltaX) < 0.5 && abs(deltaY) < 0.5 {
            return
        }

        // Get current mouse position
        guard let currentEvent = CGEvent(source: nil) else { return }
        let currentPos = currentEvent.location

        // Calculate new position
        let newPos = CGPoint(
            x: currentPos.x + deltaX,
            y: currentPos.y + deltaY
        )

        // Post mouse move event
        guard let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved,
                                      mouseCursorPosition: newPos, mouseButton: .left) else { return }
        moveEvent.post(tap: .cghidEventTap)
    }

    static func scrollByStick(x: Int, y: Int) {
        // Convert 0-255 to scroll deltas (-128 to 127), negated for natural scroll direction
        let scrollY = -Int32(Double(y - 128) * SCROLL_SENSITIVITY)
        let scrollX = -Int32(Double(x - 128) * SCROLL_SENSITIVITY)

        // Skip if movement is negligible
        if abs(scrollY) < 1 && abs(scrollX) < 1 {
            return
        }

        // Post scroll wheel event (vertical scroll is wheel1, horizontal is wheel2)
        guard let scrollEvent = CGEvent(scrollWheelEvent2Source: nil,
                                       units: .line,
                                       wheelCount: 2,
                                       wheel1: scrollY,
                                       wheel2: scrollX,
                                       wheel3: 0) else { return }
        scrollEvent.post(tap: .cghidEventTap)
    }

    // Mouse clicks
    static func leftClick() {
        logEvent("Left click")
        guard let currentEvent = CGEvent(source: nil) else { return }
        let pos = currentEvent.location

        guard let downEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown,
                                      mouseCursorPosition: pos, mouseButton: .left),
              let upEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp,
                                    mouseCursorPosition: pos, mouseButton: .left) else { return }

        downEvent.post(tap: .cghidEventTap)
        usleep(10000)  // 10ms between down and up for realistic click
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
        usleep(10000)  // 10ms between down and up for realistic click
        upEvent.post(tap: .cghidEventTap)
    }

    private static func runAppleScript(_ script: String) {
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        task.launch()
    }

    // Helper to map characters to macOS key codes
    private static func charToKeyCode(_ char: Character) -> String? {
        switch char {
        case " ": return "49"   // Space
        case "a": return "0"
        case "b": return "11"
        case "c": return "8"
        case "d": return "2"
        case "e": return "14"
        case "f": return "3"
        case "g": return "5"
        case "h": return "4"
        case "i": return "34"
        case "j": return "38"
        case "k": return "40"
        case "l": return "37"
        case "m": return "46"
        case "n": return "45"
        case "o": return "31"
        case "p": return "35"
        case "q": return "12"
        case "r": return "15"
        case "s": return "1"
        case "t": return "17"
        case "u": return "32"
        case "v": return "9"
        case "w": return "13"
        case "x": return "7"
        case "y": return "16"
        case "z": return "6"
        default: return nil
        }
    }
}

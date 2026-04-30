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

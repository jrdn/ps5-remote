import Foundation
import CoreGraphics

typealias Action = () -> Void

class Actions {
    static func logEvent(_ message: String) {
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        print("[\(timestamp)] ACTION: \(message)")
    }

    static func pressKey(_ keyCode: UInt16, modifiers: CGEventFlags = []) {
        let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)

        keyDown?.flags = modifiers
        keyUp?.flags = modifiers

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    static func typeString(_ text: String) {
        for char in text {
            if let keyCode = charToKeyCode(char) {
                pressKey(keyCode)
            }
        }
    }

    static func systemCommand(_ command: String) {
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", command]
        task.launch()
    }

    // Helper to map characters to macOS key codes
    private static func charToKeyCode(_ char: Character) -> UInt16? {
        switch char {
        case " ": return 49  // Space
        case "a": return 0
        case "b": return 11
        case "c": return 8
        case "d": return 2
        case "e": return 14
        case "f": return 3
        case "g": return 5
        case "h": return 4
        case "i": return 34
        case "j": return 38
        case "k": return 40
        case "l": return 37
        case "m": return 46
        case "n": return 45
        case "o": return 31
        case "p": return 35
        case "q": return 12
        case "r": return 15
        case "s": return 1
        case "t": return 17
        case "u": return 32
        case "v": return 9
        case "w": return 13
        case "x": return 7
        case "y": return 16
        case "z": return 6
        default: return nil
        }
    }
}

import Foundation
import CoreGraphics
import Yams

struct ConfigError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}

struct KeyCombo {
    let keyCode: CGKeyCode
    let flags: CGEventFlags
}

// A resolved binding: fires `press` on press and `release` (if any) on release of the same input
struct Rule {
    let apps: [String]?  // bundle ID substrings; nil matches any app
    let description: String
    let press: Action
    let release: Action?
}

typealias Layer = [ControllerInput: [Rule]]

struct Bindings {
    var layers: [String: Layer]
}

private let inputNames: [String: ControllerInput] = [
    "square": .button(.square), "cross": .button(.cross),
    "circle": .button(.circle), "triangle": .button(.triangle),
    "l1": .button(.l1), "r1": .button(.r1), "l2": .button(.l2),
    "l3": .button(.l3), "r3": .button(.r3),
    "share": .button(.share), "options": .button(.options),
    "ps": .button(.ps), "touchpad": .button(.touchpad),
    "dpad_up": .dpad(.up), "dpad_down": .dpad(.down),
    "dpad_left": .dpad(.left), "dpad_right": .dpad(.right),
    "left_stick_up": .leftStick(.up), "left_stick_down": .leftStick(.down),
    "left_stick_left": .leftStick(.left), "left_stick_right": .leftStick(.right),
    "right_stick_up": .rightStick(.up), "right_stick_down": .rightStick(.down),
    "right_stick_left": .rightStick(.left), "right_stick_right": .rightStick(.right),
]

private let layerNames: Set<String> = ["default", "r2"]

private let modifierNames: [String: CGEventFlags] = [
    "cmd": .maskCommand, "command": .maskCommand,
    "shift": .maskShift,
    "opt": .maskAlternate, "option": .maskAlternate, "alt": .maskAlternate,
    "ctrl": .maskControl, "control": .maskControl,
]

private let keyCodes: [String: CGKeyCode] = [
    "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7, "c": 8, "v": 9,
    "b": 11, "q": 12, "w": 13, "e": 14, "r": 15, "y": 16, "t": 17,
    "1": 18, "2": 19, "3": 20, "4": 21, "6": 22, "5": 23, "=": 24, "9": 25, "7": 26,
    "-": 27, "8": 28, "0": 29, "]": 30, "o": 31, "u": 32, "[": 33, "i": 34, "p": 35,
    "return": 36, "enter": 36, "l": 37, "j": 38, "'": 39, "k": 40, ";": 41, "\\": 42,
    ",": 43, "/": 44, "n": 45, "m": 46, ".": 47, "tab": 48, "space": 49, "`": 50,
    "backspace": 51, "delete": 51, "escape": 53, "esc": 53,
    "f1": 122, "f2": 120, "f3": 99, "f4": 118, "f5": 96, "f6": 97,
    "f7": 98, "f8": 100, "f9": 101, "f10": 109, "f11": 103, "f12": 111,
    "left": 123, "right": 124, "down": 125, "up": 126,
]

private let builtins: [String: Action] = [
    "mission_control": { Actions.toggleMissionControl() },
    "voice_control": { Actions.toggleVoiceControl() },
]

func loadBindings(path: String) throws -> Bindings {
    let text: String
    do { text = try String(contentsOfFile: path, encoding: .utf8) }
    catch { throw ConfigError("cannot read \(path): \(error.localizedDescription)") }

    guard let root = try Yams.load(yaml: text) as? [String: Any] else {
        throw ConfigError("\(path): top level must be a mapping")
    }

    var appGroups: [String: [String]] = [:]
    if let groups = root["apps"] {
        guard let groups = groups as? [String: Any] else { throw ConfigError("apps: must be a mapping") }
        for (name, value) in groups {
            appGroups[name] = try stringList(value, context: "apps.\(name)")
        }
    }

    guard let layersNode = root["layers"] as? [String: Any] else {
        throw ConfigError("layers: missing or not a mapping")
    }

    var bindings = Bindings(layers: [:])
    for (layerName, layerNode) in layersNode {
        guard layerNames.contains(layerName) else {
            throw ConfigError("layers.\(layerName): unknown layer (expected one of \(layerNames.sorted()))")
        }
        guard let layerMap = layerNode as? [String: Any] else {
            throw ConfigError("layers.\(layerName): must be a mapping")
        }
        var layer: Layer = [:]
        for (inputName, bindingNode) in layerMap {
            let ctx = "layers.\(layerName).\(inputName)"
            guard let input = inputNames[inputName] else { throw ConfigError("\(ctx): unknown input") }
            let ruleNodes = bindingNode as? [Any] ?? [bindingNode]
            layer[input] = try ruleNodes.enumerated().map { i, node in
                try parseRule(node, appGroups: appGroups, context: ruleNodes.count > 1 ? "\(ctx)[\(i)]" : ctx)
            }
        }
        bindings.layers[layerName] = layer
    }
    return bindings
}

private func parseRule(_ node: Any, appGroups: [String: [String]], context ctx: String) throws -> Rule {
    guard let map = node as? [String: Any] else { throw ConfigError("\(ctx): must be a mapping") }

    var apps: [String]? = nil
    if let appNode = map["app"] {
        apps = try stringList(appNode, context: "\(ctx).app").flatMap { appGroups[$0] ?? [$0] }
    }

    var (description, press, release) = try parseAction(map, context: ctx)
    if let releaseNode = map["release"] {
        guard release == nil else { throw ConfigError("\(ctx): release: cannot be combined with hold/click_hold") }
        guard let releaseMap = releaseNode as? [String: Any] else { throw ConfigError("\(ctx).release: must be a mapping") }
        let parsed = try parseAction(releaseMap, context: "\(ctx).release")
        guard parsed.release == nil else { throw ConfigError("\(ctx).release: cannot be hold/click_hold") }
        description += " / release: \(parsed.description)"
        release = parsed.press
    }
    return Rule(apps: apps, description: description, press: press, release: release)
}

private func parseAction(_ map: [String: Any], context ctx: String) throws -> (description: String, press: Action, release: Action?) {
    let kinds = ["key", "hold", "click", "click_hold", "builtin"].filter { map[$0] != nil }
    guard kinds.count == 1, let kind = kinds.first, let value = map[kind] as? String else {
        throw ConfigError("\(ctx): expected exactly one of key/hold/click/click_hold/builtin with a string value")
    }
    let via = map["via"] as? String
    if via != nil && (kind != "key" || via != "applescript") {
        throw ConfigError("\(ctx): via: only 'applescript' is supported, and only with key:")
    }

    switch kind {
    case "key":
        let combo = try parseCombo(value, context: ctx)
        if via == "applescript" {
            return ("\(value) (AppleScript)", { Actions.appleScriptKey(combo.keyCode, flags: combo.flags) }, nil)
        }
        return (value, { Actions.postKey(combo.keyCode, flags: combo.flags) }, nil)
    case "hold":
        let combo = try parseCombo(value, context: ctx)
        return ("hold \(value)",
                { Actions.postKeyDown(combo.keyCode, flags: combo.flags) },
                { Actions.postKeyUp(combo.keyCode, flags: combo.flags) })
    case "click":
        switch value {
        case "left":   return ("left click", { Actions.leftClick() }, nil)
        case "right":  return ("right click", { Actions.rightClick() }, nil)
        case "middle": return ("middle click", { Actions.middleClick() }, nil)
        default: throw ConfigError("\(ctx): click: must be left, right, or middle")
        }
    case "click_hold":
        guard value == "left" else { throw ConfigError("\(ctx): click_hold: only 'left' is supported") }
        return ("hold left click", { Actions.leftClickDown() }, { Actions.leftClickUp() })
    default:
        guard let action = builtins[value] else {
            throw ConfigError("\(ctx): unknown builtin '\(value)' (expected one of \(builtins.keys.sorted()))")
        }
        return (value, action, nil)
    }
}

private func parseCombo(_ text: String, context ctx: String) throws -> KeyCombo {
    let parts = text.lowercased().split(separator: "+", omittingEmptySubsequences: false).map(String.init)
    guard let keyName = parts.last, let keyCode = keyCodes[keyName] else {
        throw ConfigError("\(ctx): unknown key in '\(text)'")
    }
    var flags: CGEventFlags = []
    for mod in parts.dropLast() {
        guard let flag = modifierNames[mod] else { throw ConfigError("\(ctx): unknown modifier '\(mod)' in '\(text)'") }
        flags.insert(flag)
    }
    return KeyCombo(keyCode: keyCode, flags: flags)
}

private func stringList(_ node: Any, context ctx: String) throws -> [String] {
    if let s = node as? String { return [s] }
    if let list = node as? [String] { return list }
    throw ConfigError("\(ctx): must be a string or list of strings")
}

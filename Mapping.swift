import Foundation

enum Button: Hashable {
    case square, cross, circle, triangle
    case l1, r1, l2, r2
    case share, options
    case l3, r3
    case ps, touchpad
}

enum StickDirection: Hashable {
    case up, down, left, right
}

enum ControllerInput: Hashable {
    case button(Button)
    case buttonReleased(Button)
    case dpad(StickDirection)
    case leftStick(StickDirection)
    case rightStick(StickDirection)
}

// Written on main RunLoop thread (HID callback), read on timer thread — protected by Controller's stickLock
var r2Active: Bool = false

var bindings = Bindings(layers: [:])

// Release actions for buttons currently held, captured at press time so the release
// fires even if the frontmost app or the R2 layer changed while held
private var pendingReleases: [Button: Action] = [:]

func dispatch(input: ControllerInput) {
    if case .buttonReleased(let button) = input {
        pendingReleases.removeValue(forKey: button)?()
        return
    }

    let layer = bindings.layers[r2Active ? "r2" : "default"] ?? [:]
    guard let rules = layer[input],
          let rule = rules.first(where: { $0.apps?.contains(where: Actions.isActiveApp) ?? true })
    else { return }

    Actions.logEvent("\(Actions.getActiveAppName() ?? "unknown"): \(input) → \(rule.description)")
    rule.press()
    if case .button(let button) = input, let release = rule.release {
        pendingReleases[button] = release
    }
}

func releaseAllHeld() {
    let releases = pendingReleases.values
    pendingReleases.removeAll()
    releases.forEach { $0() }
}

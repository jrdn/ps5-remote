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

var bindings = Bindings(layers: [:]) {
    didSet { updateStickModes() }
}

// Layer hold buttons currently down, oldest first; the last one's layer is active
private var heldLayers: [(button: Button, layer: String)] = []

private func activeLayer() -> Layer? {
    heldLayers.last.flatMap { bindings.layers[$0.layer] } ?? bindings.layers["default"]
}

// Written on main RunLoop thread, read on timer thread
private let stickModeLock = NSLock()
private var stickModes: (left: StickMode, right: StickMode) = (.directions, .directions)

func currentStickModes() -> (left: StickMode, right: StickMode) {
    stickModeLock.lock()
    defer { stickModeLock.unlock() }
    return stickModes
}

private func updateStickModes() {
    let layer = activeLayer()
    stickModeLock.lock()
    stickModes = (layer?.leftStick ?? .directions, layer?.rightStick ?? .directions)
    stickModeLock.unlock()
}

// Release actions for buttons currently held, captured at press time so the release
// fires even if the frontmost app or the layer changed while held
private var pendingReleases: [Button: Action] = [:]

func dispatch(input: ControllerInput) {
    if case .buttonReleased(let button) = input {
        if let i = heldLayers.firstIndex(where: { $0.button == button }) {
            heldLayers.remove(at: i)
            updateStickModes()
            return
        }
        pendingReleases.removeValue(forKey: button)?()
        return
    }

    if case .button(let button) = input,
       let name = bindings.layers.first(where: { $0.value.hold == button })?.key {
        heldLayers.append((button, name))
        updateStickModes()
        return
    }

    guard let layer = activeLayer() else { return }
    guard let rules = layer.rules[input],
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
    heldLayers.removeAll()
    updateStickModes()
}

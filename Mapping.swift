import Foundation

enum ControllerInput: Hashable {
    case button(String)
    case dpad(String)
    case leftStick(String)   // "Up", "Down", "Left", "Right"
    case rightStick(String)  // "Up", "Down", "Left", "Right"
}

// Global state for R2 modifier layer (set by Controller.swift)
var r2Active: Bool = false

var defaultMapping: [ControllerInput: Action] = [
    // Buttons
    .button("Square"): {
        if Actions.isActiveApp("Safari") {
            Actions.logEvent("Safari: Opening new tab")
            Actions.systemCommand("open 'javascript:void(0)'")  // Example
        } else if Actions.isActiveApp("Chrome") {
            Actions.logEvent("Chrome: Opening new tab")
        } else {
            Actions.logEvent("Square pressed in \(Actions.getActiveAppName() ?? "unknown app")")
        }
    },

    .button("X"):        { Actions.logEvent("X pressed") },
    .button("Circle"):   { Actions.logEvent("Circle pressed") },
    .button("Triangle"): { Actions.logEvent("Triangle pressed") },

    .button("L1"):       { Actions.leftClick() },
    .button("R1"):       { Actions.rightClick() },
    .button("L2"):       { Actions.logEvent("L2 pressed") },
    .button("R2"):       { Actions.logEvent("R2 pressed") },

    .button("Share"):    { Actions.switchSpaceLeft() },
    .button("Options"):  { Actions.switchSpaceRight() },

    .button("L3"):       { Actions.logEvent("L3 pressed") },
    .button("R3"):       { Actions.logEvent("R3 pressed") },

    .button("PS"):       { Actions.logEvent("PS pressed") },
    .button("Touchpad"): { Actions.toggleMissionControl() },

    // D-Pad
    .dpad("Up"):   { Actions.logEvent("D-Pad Up") },
    .dpad("Down"): { Actions.logEvent("D-Pad Down") },
    .dpad("Left"): {
        if Actions.isActiveApp("ghostty") {
            Actions.cmdBracketLeft()
        } else {
            Actions.logEvent("D-Pad Left")
        }
    },
    .dpad("Right"): {
        if Actions.isActiveApp("ghostty") {
            Actions.cmdBracketRight()
        } else {
            Actions.logEvent("D-Pad Right")
        }
    },

    // Left stick (directional events when R2 not held)
    .leftStick("Up"): {
        if Actions.isActiveApp("Emacs") {
            Actions.shiftArrowUp()
        } else if Actions.isActiveApp("ghostty") {
            Actions.cmdBacktick()
        } else {
            Actions.logEvent("Left Stick Up")
        }
    },
    .leftStick("Down"): {
        if Actions.isActiveApp("Emacs") {
            Actions.shiftArrowDown()
        } else if Actions.isActiveApp("ghostty") {
            Actions.cmdShiftBacktick()
        } else {
            Actions.logEvent("Left Stick Down")
        }
    },
    .leftStick("Left"): {
        if Actions.isActiveApp("Emacs") {
            Actions.shiftArrowLeft()
        } else if Actions.isActiveApp("ghostty") {
            Actions.controlShiftTab()
        } else {
            Actions.logEvent("Left Stick Left")
        }
    },
    .leftStick("Right"): {
        if Actions.isActiveApp("Emacs") {
            Actions.shiftArrowRight()
        } else if Actions.isActiveApp("ghostty") {
            Actions.controlTab()
        } else {
            Actions.logEvent("Left Stick Right")
        }
    },

    // Right stick (directional events when R2 not held)
    .rightStick("Up"):    { Actions.logEvent("Right Stick Up") },
    .rightStick("Down"):  { Actions.logEvent("Right Stick Down") },
    .rightStick("Left"):  { Actions.logEvent("Right Stick Left") },
    .rightStick("Right"): { Actions.logEvent("Right Stick Right") },
]

var r2Mapping: [ControllerInput: Action] = [
    // Buttons - custom R2 layer actions
    .button("Square"): { Actions.logEvent("R2 + Square pressed") },
    .button("X"):      { Actions.logEvent("R2 + X pressed") },
    .button("Circle"): { Actions.logEvent("R2 + Circle pressed") },
    .button("Triangle"): { Actions.logEvent("R2 + Triangle pressed") },

    .button("L1"): { Actions.logEvent("R2 + L1 pressed") },
    .button("R1"): { Actions.logEvent("R2 + R1 pressed") },
    .button("L2"): { Actions.logEvent("R2 + L2 pressed") },
    .button("R2"): { Actions.logEvent("R2 + R2 pressed") },

    .button("Share"):    { Actions.logEvent("R2 + Share pressed") },
    .button("Options"):  { Actions.logEvent("R2 + Options pressed") },

    .button("L3"): { Actions.logEvent("R2 + L3 pressed") },
    .button("R3"): { Actions.logEvent("R2 + R3 pressed") },

    .button("PS"):       { Actions.logEvent("R2 + PS pressed") },
    .button("Touchpad"): { Actions.logEvent("R2 + Touchpad pressed") },

    // D-Pad in R2 mode
    .dpad("Up"):    { Actions.logEvent("R2 + D-Pad Up") },
    .dpad("Down"):  { Actions.logEvent("R2 + D-Pad Down") },
    .dpad("Left"):  { Actions.logEvent("R2 + D-Pad Left") },
    .dpad("Right"): { Actions.logEvent("R2 + D-Pad Right") },

    // Sticks in R2 mode (note: mouse/scroll movement handled directly in Controller.swift)
    .leftStick("Up"):    { Actions.logEvent("R2 + Left Stick Up") },
    .leftStick("Down"):  { Actions.logEvent("R2 + Left Stick Down") },
    .leftStick("Left"):  { Actions.logEvent("R2 + Left Stick Left") },
    .leftStick("Right"): { Actions.logEvent("R2 + Left Stick Right") },

    .rightStick("Up"):    { Actions.logEvent("R2 + Right Stick Up") },
    .rightStick("Down"):  { Actions.logEvent("R2 + Right Stick Down") },
    .rightStick("Left"):  { Actions.logEvent("R2 + Right Stick Left") },
    .rightStick("Right"): { Actions.logEvent("R2 + Right Stick Right") },
]

func dispatch(input: ControllerInput) {
    let mapping = r2Active ? r2Mapping : defaultMapping
    mapping[input]?()
}

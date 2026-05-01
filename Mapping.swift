import Foundation

enum ControllerInput: Hashable {
    case button(String)
    case buttonReleased(String)
    case dpad(String)
    case leftStick(String)   // "Up", "Down", "Left", "Right"
    case rightStick(String)  // "Up", "Down", "Left", "Right"
}

// Global state for R2 modifier layer (set by Controller.swift)
var r2Active: Bool = false

var defaultMapping: [ControllerInput: Action] = [
    // Buttons
    .button("Square"): { },

    .button("X"):        { Actions.sendEnter() },
    .button("Circle"):   { Actions.sendEscape() },
    .button("Triangle"): { },

    .button("L1"):       { Actions.leftClickDown() },
    .buttonReleased("L1"): { Actions.leftClickUp() },
    .button("R1"):       { },
    .button("L2"):       { Actions.startDictationPress() },
    .buttonReleased("L2"): { Actions.startDictationRelease() },
    .button("R2"):       { },

    .button("Share"):    { Actions.switchSpaceLeft() },
    .button("Options"):  { Actions.switchSpaceRight() },

    .button("L3"):       { },
    .button("R3"):       { },

    .button("PS"):       { Actions.startDictationPress() },
    .button("Touchpad"): { Actions.toggleMissionControl() },

    // D-Pad
    .dpad("Up"):    { Actions.arrowUp() },
    .dpad("Down"):  { Actions.arrowDown() },
    .dpad("Left"):  { Actions.arrowLeft() },
    .dpad("Right"): { Actions.arrowRight() },

    // Left stick (directional events when R2 not held)
    .leftStick("Up"): {
        if Actions.isActiveApp("Emacs") {
            Actions.shiftArrowUp()
        } else if Actions.isActiveApp("ghostty") {
            Actions.cmdBacktick()
        }
    },
    .leftStick("Down"): {
        if Actions.isActiveApp("Emacs") {
            Actions.shiftArrowDown()
        } else if Actions.isActiveApp("ghostty") {
            Actions.cmdShiftBacktick()
        }
    },
    .leftStick("Left"): {
        if Actions.isActiveApp("Emacs") {
            Actions.shiftArrowLeft()
        } else if Actions.isActiveApp("ghostty") {
            Actions.controlShiftTab()
        }
    },
    .leftStick("Right"): {
        if Actions.isActiveApp("Emacs") {
            Actions.shiftArrowRight()
        } else if Actions.isActiveApp("ghostty") {
            Actions.controlTab()
        }
    },

    // Right stick (directional events when R2 not held)
    .rightStick("Up"):    { },
    .rightStick("Down"):  { },
    .rightStick("Left"):  { },
    .rightStick("Right"): { },
]

var r2Mapping: [ControllerInput: Action] = [
    // Buttons - custom R2 layer actions
    .button("Square"): { },
    .button("X"):      { },
    .button("Circle"): { },
    .button("Triangle"): { },

    .button("L1"): { Actions.leftClickDown() },
    .buttonReleased("L1"): { Actions.leftClickUp() },
    .button("R1"): { Actions.rightClick() },
    .button("L2"): { Actions.startDictationPress() },
    .buttonReleased("L2"): { Actions.startDictationRelease() },
    .button("R2"): { },

    .button("Share"):    { },
    .button("Options"):  { },

    .button("L3"): { },
    .button("R3"): { },

    .button("PS"):       { },
    .button("Touchpad"): { },

    // D-Pad in R2 mode
    .dpad("Up"):    { },
    .dpad("Down"):  { },
    .dpad("Left"):  { },
    .dpad("Right"): { },

    // Sticks in R2 mode (note: mouse/scroll movement handled directly in Controller.swift)
    .leftStick("Up"):    { },
    .leftStick("Down"):  { },
    .leftStick("Left"):  { },
    .leftStick("Right"): { },

    .rightStick("Up"):    { },
    .rightStick("Down"):  { },
    .rightStick("Left"):  { },
    .rightStick("Right"): { },
]

func dispatch(input: ControllerInput) {
    let mapping = r2Active ? r2Mapping : defaultMapping
    mapping[input]?()
}

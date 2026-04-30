import Foundation

// Action is defined in Actions.swift as: typealias Action = () -> Void

enum ControllerInput: Hashable {
    case button(String)
    case dpad(String)
}

var buttonMapping: [ControllerInput: Action] = [
    // Buttons - example with context-aware actions
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
    .dpad("Up"):    { Actions.logEvent("D-Pad Up") },
    .dpad("Down"):  { Actions.logEvent("D-Pad Down") },
    .dpad("Left"):  { Actions.logEvent("D-Pad Left") },
    .dpad("Right"): { Actions.logEvent("D-Pad Right") },
]

func dispatch(input: ControllerInput) {
    buttonMapping[input]?()
}

import Foundation

// Action is defined in Actions.swift as: typealias Action = () -> Void

enum ControllerInput: Hashable {
    case button(String)
    case dpad(String)
}

var buttonMapping: [ControllerInput: Action] = [
    // Buttons
    .button("Square"):   { Actions.logEvent("Square pressed") },
    .button("X"):        { Actions.logEvent("X pressed") },
    .button("Circle"):   { Actions.logEvent("Circle pressed") },
    .button("Triangle"): { Actions.logEvent("Triangle pressed") },

    .button("L1"):       { Actions.logEvent("L1 pressed") },
    .button("R1"):       { Actions.logEvent("R1 pressed") },
    .button("L2"):       { Actions.logEvent("L2 pressed") },
    .button("R2"):       { Actions.logEvent("R2 pressed") },

    .button("Share"):    { Actions.logEvent("Share pressed") },
    .button("Options"):  { Actions.logEvent("Options pressed") },

    .button("L3"):       { Actions.logEvent("L3 pressed") },
    .button("R3"):       { Actions.logEvent("R3 pressed") },

    .button("PS"):       { Actions.logEvent("PS pressed") },
    .button("Touchpad"): { Actions.logEvent("Touchpad pressed") },

    // D-Pad
    .dpad("Up"):    { Actions.logEvent("D-Pad Up") },
    .dpad("Down"):  { Actions.logEvent("D-Pad Down") },
    .dpad("Left"):  { Actions.logEvent("D-Pad Left") },
    .dpad("Right"): { Actions.logEvent("D-Pad Right") },
]

func dispatch(input: ControllerInput) {
    buttonMapping[input]?()
}

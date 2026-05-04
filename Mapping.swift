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

var defaultMapping: [ControllerInput: Action] = [
    .button(.cross):    { Actions.sendEnter() },
    .button(.circle):   { Actions.sendEscape() },
    .button(.triangle): {
        if Actions.isActiveBrowser() { Actions.closeTab() }
    },

    .button(.l1): {
        if Actions.isActiveApp("ghostty") || Actions.isActiveApp("iterm2") {
            Actions.cmdShiftBacktick()
        } else if Actions.isActiveBrowser() {
            Actions.browserPrevTab()
        } else {
            Actions.leftClickDown()
        }
    },
    .buttonReleased(.l1): {
        if !Actions.isActiveBrowser() && !Actions.isActiveApp("ghostty") && !Actions.isActiveApp("iterm2") {
            Actions.leftClickUp()
        }
    },
    .button(.r1): {
        if Actions.isActiveApp("ghostty") || Actions.isActiveApp("iterm2") {
            Actions.cmdBacktick()
        } else if Actions.isActiveBrowser() {
            Actions.browserNextTab()
        }
    },

    .button(.l2):         { Actions.startDictationPress() },
    .buttonReleased(.l2): { Actions.startDictationRelease() },

    .button(.share):    { Actions.switchSpaceLeft() },
    .button(.options):  { Actions.switchSpaceRight() },
    .button(.r3):       { Actions.toggleVoiceControl() },
    .button(.ps):       { Actions.startDictationPressPS() },
    .button(.touchpad): { Actions.toggleMissionControl() },

    .dpad(.up):    { Actions.arrowUp() },
    .dpad(.down):  { Actions.arrowDown() },
    .dpad(.left):  { Actions.arrowLeft() },
    .dpad(.right): { Actions.arrowRight() },

    .leftStick(.up): {
        if Actions.isActiveApp("Emacs") {
            Actions.shiftArrowUp()
        } else if Actions.isActiveApp("ghostty") || Actions.isActiveApp("iterm2") {
            Actions.iterm2PaneUp()
        }
    },
    .leftStick(.down): {
        if Actions.isActiveApp("Emacs") {
            Actions.shiftArrowDown()
        } else if Actions.isActiveApp("ghostty") || Actions.isActiveApp("iterm2") {
            Actions.iterm2PaneDown()
        }
    },
    .leftStick(.left): {
        if Actions.isActiveApp("Emacs") {
            Actions.shiftArrowLeft()
        } else if Actions.isActiveApp("ghostty") || Actions.isActiveApp("iterm2") {
            Actions.iterm2PaneLeft()
        }
    },
    .leftStick(.right): {
        if Actions.isActiveApp("Emacs") {
            Actions.shiftArrowRight()
        } else if Actions.isActiveApp("ghostty") || Actions.isActiveApp("iterm2") {
            Actions.iterm2PaneRight()
        }
    },
]

var r2Mapping: [ControllerInput: Action] = [
    .button(.square):         { Actions.middleClick() },
    .button(.l1):             { Actions.leftClickDown() },
    .buttonReleased(.l1):     { Actions.leftClickUp() },
    .button(.r1):             { Actions.rightClick() },
    .button(.l2):             { Actions.startDictationPress() },
    .buttonReleased(.l2):     { Actions.startDictationRelease() },
]

func dispatch(input: ControllerInput) {
    let mapping = r2Active ? r2Mapping : defaultMapping
    mapping[input]?()
}

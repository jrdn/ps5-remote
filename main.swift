import Foundation

let debugMode = CommandLine.arguments.contains("--debug")

Actions.checkVoiceControlShortcuts()

let controller = PS5Controller()
controller.start()

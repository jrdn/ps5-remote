import AppKit

let debugMode = CommandLine.arguments.contains("--debug")

// Launched from Finder/login: send output to a log file (appending, reset once it passes 5 MB)
if isatty(STDOUT_FILENO) == 0 {
    let size = (try? FileManager.default.attributesOfItem(atPath: logPath)[.size] as? Int) ?? 0
    if size > 5_000_000 { try? Data().write(to: URL(fileURLWithPath: logPath)) }
    freopen(logPath, "a", stdout)
    freopen(logPath, "a", stderr)
    setvbuf(stdout, nil, _IOLBF, 0)
}

// Default config lives in ~/.config/ps5-remote, seeded from the bundled bindings.yaml on first launch
func defaultConfigPath() -> String {
    let file = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".config/ps5-remote/bindings.yaml")
    if !FileManager.default.fileExists(atPath: file.path),
       let seed = Bundle.main.url(forResource: "bindings", withExtension: "yaml") {
        try? FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? FileManager.default.copyItem(at: seed, to: file)
    }
    return file.path
}

let configPath: String = {
    let args = CommandLine.arguments
    if let i = args.firstIndex(of: "--config"), i + 1 < args.count { return args[i + 1] }
    return defaultConfigPath()
}()

NSApplication.shared.setActivationPolicy(.accessory)

let statusBar = StatusBarController(configPath: configPath)
statusBar.reloadConfig()

Actions.checkVoiceControlShortcuts()

let controller = PS5Controller()
controller.onConnectionChange = { statusBar.setConnected($0) }
controller.start()
NSApplication.shared.run()

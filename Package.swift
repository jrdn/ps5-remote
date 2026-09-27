// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ps5-remote",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "ps5-remote",
            dependencies: ["Yams"],
            path: ".",
            exclude: ["BINDINGS.md", "README.md", "bindings.yaml", "mise.toml", "ps5-remote", "Info.plist", "AppIcon.png"],
            sources: ["main.swift", "Controller.swift", "Actions.swift", "Mapping.swift", "Config.swift", "App.swift"]
        ),
    ]
)

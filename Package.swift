// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TokenSaver",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "TokenSaverCore", targets: ["TokenSaverCore"]),
        .executable(name: "tokensaver", targets: ["TokenSaverCLI"]),
    ],
    targets: {
        var targets: [Target] = [
            .target(
                name: "TokenSaverCore",
                swiftSettings: [
                    .enableUpcomingFeature("StrictConcurrency"),
                ]),
            .target(
                name: "TokenSaverInstaller",
                dependencies: ["TokenSaverCore"],
                path: "Sources/TokenSaverInstaller",
                swiftSettings: [
                    .enableUpcomingFeature("StrictConcurrency"),
                ]),
            .executableTarget(
                name: "TokenSaverCLI",
                dependencies: ["TokenSaverCore", "TokenSaverInstaller"],
                path: "Sources/TokenSaverCLI",
                swiftSettings: [
                    .enableUpcomingFeature("StrictConcurrency"),
                ]),
        ]

        #if os(macOS)
        targets.append(contentsOf: [
            .executableTarget(
                name: "TokenSaverApp",
                dependencies: ["TokenSaverCore"],
                path: "Sources/TokenSaverApp",
                swiftSettings: [
                    .enableUpcomingFeature("StrictConcurrency"),
                ]),
            .executableTarget(
                name: "TokenSaverWidget",
                dependencies: ["TokenSaverCore"],
                path: "Sources/TokenSaverWidget",
                swiftSettings: [
                    .enableUpcomingFeature("StrictConcurrency"),
                ]),
        ])
        #endif

        targets.append(
            .testTarget(
                name: "TokenSaverTests",
                dependencies: ["TokenSaverCore", "TokenSaverInstaller"],
                path: "Tests/TokenSaverTests",
                swiftSettings: [
                    .enableUpcomingFeature("StrictConcurrency"),
                ]))

        return targets
    }())

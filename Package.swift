// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Vois",
    platforms: [.macOS(.v15)],
    dependencies: [
        // Pins mlx-swift 0.30.2, MisakiSwift 1.0.6 internally.
        .package(url: "https://github.com/mlalma/kokoro-ios.git", exact: "1.0.11"),
        .package(url: "https://github.com/tisfeng/SelectedTextKit.git", from: "2.6.4"),
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "3.0.1"),
    ],
    targets: [
        .executableTarget(
            name: "Vois",
            dependencies: [
                .product(name: "KokoroSwift", package: "kokoro-ios"),
                "SelectedTextKit",
                "KeyboardShortcuts",
            ]
        ),
        .testTarget(name: "VoisTests", dependencies: ["Vois"]),
    ]
)

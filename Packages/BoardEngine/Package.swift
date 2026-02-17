// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "BoardEngine",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "BoardEngine",
            targets: ["BoardEngine"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "BoardEngine",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("MemberImportVisibility")
            ]
        ),
        .testTarget(
            name: "BoardEngineTests",
            dependencies: ["BoardEngine"]
        ),
    ]
)

// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "BrushEngine",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "BrushEngine",
            targets: ["BrushEngine"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "BrushEngine",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("MemberImportVisibility")
            ]
        ),
        .testTarget(
            name: "BrushEngineTests",
            dependencies: ["BrushEngine"]
        ),
    ]
)

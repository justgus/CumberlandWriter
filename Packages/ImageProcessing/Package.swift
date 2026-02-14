// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "ImageProcessing",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "ImageProcessing",
            targets: ["ImageProcessing"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ImageProcessing",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("MemberImportVisibility")
            ]
        ),
        .testTarget(
            name: "ImageProcessingTests",
            dependencies: ["ImageProcessing"]
        ),
    ]
)

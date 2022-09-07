// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "Media",
    platforms: [
        .iOS(.v14),
        .macOS(.v12),
        .tvOS(.v14),
        .watchOS(.v7)
    ],
    products: [
        .library(
            name: "Media",
            targets: ["Media"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/vmanot/Swallow.git", branch: "master")
    ],
    targets: [
        .target(
            name: "Media",
            dependencies: ["Swallow"],
            path: "Sources"
        ),
        .testTarget(
            name: "MediaTests",
            dependencies: ["Media"],
            path: "Tests"
        )
    ]
)

// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "Media",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "Media",
            targets: [
                "Media"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftUIX/SwiftUIX.git", branch: "master"),
        .package(url: "https://github.com/SwiftUIX/SwiftUIZ.git", branch: "main"),
        .package(url: "https://github.com/vmanot/Merge.git", branch: "master"),
        .package(url: "https://github.com/vmanot/Swallow.git", branch: "master"),
    ],
    targets: [
        .target(
            name: "Media",
            dependencies: [
                "Merge",
                "Swallow",
                "SwiftUIX",
                "SwiftUIZ",
            ]
        ),
        .testTarget(
            name: "MediaTests",
            dependencies: [
                "Media"
            ],
            path: "Tests"
        )
    ]
)

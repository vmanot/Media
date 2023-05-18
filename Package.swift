// swift-tools-version:5.7

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
            targets: [
                "Media"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/kean/Nuke", from: "12.0.0-beta.5"),
        .package(url: "https://github.com/SwiftUIX/SwiftUIX.git", branch: "master"),
        .package(url: "https://github.com/vmanot/Swallow.git", branch: "master")
    ],
    targets: [
        .target(
            name: "Media",
            dependencies: [
                .product(name: "NukeUI", package: "Nuke"),
                "SwiftUIX",
                "Swallow"
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

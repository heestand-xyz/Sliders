// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Sliders",
    platforms: [
        .iOS(.v17),
        .macOS(.v15),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "Sliders",
            targets: ["Sliders"]),
    ],
    dependencies: [
        .package(url: "https://github.com/heestand-xyz/MultiViews", from: "3.2.0"),
    ],
    targets: [
        .target(
            name: "Sliders",
            dependencies: [
                "MultiViews",
            ]
        ),
    ]
)

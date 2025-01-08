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
    targets: [
        .target(
            name: "Sliders"),
    ]
)

// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Aperture",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .macCatalyst(.v14),
    ],
    products: [
        .library(
            name: "Aperture",
            targets: ["Aperture"]
        ),
    ],
    targets: [
        .target(
            name: "Aperture"
        ),
    ]
)

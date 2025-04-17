// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-promise",
    platforms: [.iOS(.v13),.watchOS(.v6),.macOS(.v10_15),.tvOS(.v13)],
    products: [
        .library(
            name: "Promise",
            targets: ["Promise"]),
    ],
    targets: [
        .target(
            name: "Promise"),
        .testTarget(
            name: "PromiseTests",
            dependencies: ["Promise"]
        ),
    ]
)

// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Channel",
    products: [
        .library(name: "Channel", targets: ["Channel"]),
    ],
    dependencies: [
        .package(url: "https://github.com/rhx/CircularQueue.git", .branch("master")),
    ],
    targets: [
        .target(name: "Channel", dependencies: ["CircularQueue"]),
        .testTarget(name: "ChannelTests", dependencies: ["Channel"]),
    ]
)

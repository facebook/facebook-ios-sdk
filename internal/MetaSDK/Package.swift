// swift-tools-version: 5.6
import PackageDescription

let package = Package(
    name: "MetaSDK",
    platforms: [
        .iOS(.v12),
    ],
    products: [
        .library(
            name: "MetaLogin",
            targets: ["MetaLogin"]),
    ],
    targets: [
        .target(
            name: "MetaLogin",
            dependencies: []),
        .testTarget(
            name: "MetaLoginTests",
            dependencies: ["MetaLogin"]),
    ]
)

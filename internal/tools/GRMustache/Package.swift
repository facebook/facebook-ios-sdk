// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Mustache",
    products: [
        .library(
            name: "Mustache",
            targets: ["Mustache"]
        )
    ],
    targets: [
        .target(
            name: "Mustache",
            dependencies: [],
            path: "Sources")
    ]
) 

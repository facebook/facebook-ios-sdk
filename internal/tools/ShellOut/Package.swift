// swift-tools-version:4.2

/**
 *  ShellOut
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import PackageDescription

let package = Package(
    name: "ShellOut",
    products: [
        .library(name: "ShellOut", targets: ["ShellOut"])
    ],
    targets: [
        .target(
            name: "ShellOut",
            path: "Sources"
        ),
        .testTarget(
            name: "ShellOutTests",
            dependencies: ["ShellOut"]
        )
    ]
)

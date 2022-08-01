// swift-tools-version: 5.6

/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import PackageDescription

let package = Package(
    name: "MetaSDK",
    platforms: [
        .iOS(.v13),
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

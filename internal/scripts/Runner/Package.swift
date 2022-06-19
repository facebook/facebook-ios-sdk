// swift-tools-version:5.4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import PackageDescription

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

enum HostType: String {
    static let `default`: HostType = .internal

    case `internal`, external

    static var current: HostType {
        if let hostTypePointer = getenv("HOST_TYPE") {
            let hostType = String(cString: hostTypePointer)
            return HostType(rawValue: hostType) ?? .internal
        } else {
            return .internal
        }
    }

    var dependencies: [Package.Dependency] {
        switch self {
        case .external:
            return [
                .package(
                    name: "swift-argument-parser",
                    url: "https://github.com/apple/swift-argument-parser",
                    from: "1.0.1"
                ),
                .package(
                    name: "ShellOut",
                    url: "https://github.com/JohnSundell/ShellOut",
                    from: "2.3.0"
                ),
                .package(
                    name: "Mustache",
                    url: "https://github.com/groue/GRMustache.swift",
                    from: "4.0.1"
                )
            ]
        case .internal:
            return [
                .package(name: "swift-argument-parser", path: "../../../../VendorLib/swift-argument-parser"),
                .package(name: "ShellOut", path: "../../../../VendorLib/ShellOut"),
                .package(name: "Mustache", path: "../../../../VendorLib/GRMustache")
            ]
        }
    }
}

let package = Package(
    name: "Runner",
    platforms: [.macOS("10.12")],
    products: [
        .executable(
            name: "runner",
            targets: ["Runner"]
        )
    ],
    dependencies: HostType.current.dependencies,
    targets: [
        .executableTarget(
            name: "Runner",
            dependencies: [
                .product(name: "ShellOut", package: "ShellOut"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Mustache", package: "Mustache"),
            ],
            resources: [
                .process("Templates")
            ]
        ),
        .testTarget(
            name: "RunnerTests",
            dependencies: ["Runner"])
    ]
)

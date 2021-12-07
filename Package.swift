// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

// @lint-ignore-every LICENSELINT

/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import PackageDescription
import Foundation

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

enum BinarySource {
    case local, remote

    static var current: Self {
        if getenv("USE_LOCAL_FB_BINARIES") != nil {
            return .local
        } else {
            return .remote
        }
    }
}

struct BinaryTargets {
    let source: BinarySource

    var aem: Target {
        switch source {
        case .local:
            return .binaryTarget(
                name: "FBAEMKit",
                path: "build/XCFrameworks/Static/FBAEMKit.xcframework"
            )
        case .remote:
            return .binaryTarget(
                name: "FBAEMKit",
                url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.2.0/FBAEMKit-Static_XCFramework.zip",
                checksum: "d3de558731ba281d9555002c7892ebc735232df55f2f5f3faf0bce64ca0ef51e"
            )
        }
    }

    var basics: Target {
        switch source {
        case .local:
            return .binaryTarget(
                name: "FBSDKCoreKit_Basics",
                path: "build/XCFrameworks/Static/FBSDKCoreKit_Basics.xcframework"
            )
        case .remote:
            return .binaryTarget(
                name: "FBSDKCoreKit_Basics",
                url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.2.0/FBSDKCoreKit_Basics-Static_XCFramework.zip",
                checksum: "ab90cdc8b3973da19be9b1a120807c0189adad1b0e34dc9534170bfcef9d3f55"
            )
        }
    }

    var core: Target {
        switch source {
        case .local:
            return .binaryTarget(
                name: "FBSDKCoreKit",
                path: "build/XCFrameworks/Static/FBSDKCoreKit.xcframework"
            )
        case .remote:
            return .binaryTarget(
                name: "FBSDKCoreKit",
                url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.2.0/FBSDKCoreKit-Static_XCFramework.zip",
                checksum: "f8b57bfbd797c3296b610b75767c1531d66b5f6c23b9865aa688124da1ea20ac"
            )
        }
    }

    var login: Target {
        switch source {
        case .local:
            return .binaryTarget(
                name: "FBSDKLoginKit",
                path: "build/XCFrameworks/Static/FBSDKLoginKit.xcframework"
            )
        case .remote:
            return .binaryTarget(
                name: "FBSDKLoginKit",
                url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.2.0/FBSDKLoginKit-Static_XCFramework.zip",
                checksum: "da310bab209675808ea0923ab428e3109b7a838f145f3e03a3516e5f5e25545c"
            )
        }
    }

    var share: Target {
        switch source {
        case .local:
            return .binaryTarget(
                name: "FBSDKShareKit",
                path: "build/XCFrameworks/Static/FBSDKShareKit.xcframework"
            )
        case .remote:
            return .binaryTarget(
                name: "FBSDKShareKit",
                url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.2.0/FBSDKShareKit-Static_XCFramework.zip",
                checksum: "d9c386a2ecbf2e766ceed989cb47998ad960694644cf76fd1856d74cfca9a1d2"
            )
        }
    }

    var gamingServices: Target {
        switch source {
        case .local:
            return .binaryTarget(
                name: "FacebookGamingServices",
                path: "build/XCFrameworks/Static/FacebookGamingServices.xcframework"
            )
        case .remote:
            return .binaryTarget(
                name: "FacebookGamingServices",
                url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.2.0/FacebookGamingServices-Static_XCFramework.zip",
                checksum: "8e41800362a95f6e46039e9724d909e083879382fdca68eb41be053e8f903123"
            )
        }
    }

    var fbsdkGamingServices: Target {
        switch source {
        case .local:
            return .binaryTarget(
                name: "FBSDKGamingServicesKit",
                path: "build/XCFrameworks/Static/FBSDKGamingServicesKit.xcframework"
            )
        case .remote:
            return .binaryTarget(
                name: "FBSDKGamingServicesKit",
                url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.2.0/FBSDKGamingServicesKit-Static_XCFramework.zip",
                checksum: "4e3458a9fec19f5e0b922c4d4565b615b8d40685cbdff4b90ed6bed893b70f79"
            )
        }
    }
}

let targets = BinaryTargets(source: .current)

let package = Package(
    name: "Facebook",
    platforms: [
        .iOS(.v10),
        .tvOS(.v10)
    ],
    products: [
         // The Kernel of the SDK. Must be included as a runtime dependency.
        .library(
            name: "FacebookBasics",
            targets: ["FBSDKCoreKit_Basics"]
        ),

        /*
          The Core SDK library that provides two importable modules:

            - FacebookCore which includes the most current interface and
              will contain interfaces for new features written in Swift

            - FBSDKCoreKit which contains legacy Objective-C interfaces
              that will be used to maintain backwards compatibility with
              types that have been converted to Swift.
              This will not contain interfaces for new features written in Swift.
        */
        .library(
            name: "FacebookCore",
            targets: ["FacebookCore", "FBSDKCoreKit"]
        ),

        //  The Facebook Login SDK
        .library(
            name: "FacebookLogin",
            targets: ["FacebookLogin"]
        ),

        //  The Facebook Share SDK
        .library(
            name: "FacebookShare",
            targets: ["FBSDKShareKit", "FacebookShare"]
        ),

        //  The Facebook Gaming Services SDK
        .library(
            name: "FacebookGamingServices",
            targets: ["FacebookGamingServices", "FBSDKGamingServicesKit"]
        ),

        // The Facebook AEM Kit
        .library(
            name: "FacebookAEM",
            targets: ["FBAEMKit", "FacebookAEM"]
        )
    ],
    targets: [
        // The kernel of the SDK
        targets.basics,

        /*
          The legacy Objective-C implementation that will be converted to Swift.
          This will not contain interfaces for new features written in Swift.
        */
        targets.aem,

        // The main AEM module
        .target(
          name: "FacebookAEM",
          dependencies: ["FBAEMKit"]
        ),

        /*
          The legacy Objective-C implementation that will be converted to Swift.
          This will not contain interfaces for new features written in Swift.
        */
        targets.core,

        // The main Core SDK module
        .target(
            name: "FacebookCore",
            dependencies: ["FacebookAEM", "FBSDKCoreKit_Basics", "FBSDKCoreKit"],
            linkerSettings: [
                .linkedLibrary("c++"),
                .linkedLibrary("z"),
                .linkedFramework("Accelerate")
            ]
        ),

        /*
          The legacy Objective-C implementation that will be converted to Swift.
          This will not contain interfaces for new features written in Swift.
        */
        targets.login,

        // The main Login SDK module
        .target(
            name: "FacebookLogin",
            dependencies: ["FacebookCore", "FBSDKLoginKit"]
        ),

        /*
          The legacy Objective-C implementation that will be converted to Swift.
          This will not contain interfaces for new features written in Swift.
        */
        targets.share,

        // The main Share SDK module
        .target(
            name: "FacebookShare",
            dependencies: ["FacebookCore", "FBSDKShareKit"]
        ),

        // The main Facebook Gaming Services module
        targets.gamingServices,

        /*
          Wrappers for backwards compatibility ObjC interfaces.
        */
        targets.fbsdkGamingServices,
    ],
    cxxLanguageStandard: CXXLanguageStandard.cxx11
)

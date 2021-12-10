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
                url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.2.1/FBAEMKit-Static_XCFramework.zip",
                checksum: "215fcc2fb0c1d5992efaaf9cfba8feb2704a1ebc4b4a235ac6fb25ac21ccb5e4"
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
                url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.2.1/FBSDKCoreKit_Basics-Static_XCFramework.zip",
                checksum: "c09f34bc45faaa6397e263a27a4c5fa6518984f56402cb627f1a2459107b77c3"
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
                url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.2.1/FBSDKCoreKit-Static_XCFramework.zip",
                checksum: "f85f4e90f771dafb4530594d3b54c0968f9f3182e6a746c026c07401bb92191a"
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
                url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.2.1/FBSDKLoginKit-Static_XCFramework.zip",
                checksum: "7bdc3e74b26f2a163dae55e492f3d158f01c349a3c23bcc74ff0d3f541213ed2"
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
                url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.2.1/FBSDKShareKit-Static_XCFramework.zip",
                checksum: "f2fb23cb1d31c7a08d877b7ac5b6337375cac78d9c1d647e3e01826fbe60de18"
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
                url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.2.1/FacebookGamingServices-Static_XCFramework.zip",
                checksum: "44b6aa2f398503779bc28a311104553bff328344a15254e6d34ccdeaa621adf7"
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
                url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.2.1/FBSDKGamingServicesKit-Static_XCFramework.zip",
                checksum: "af605ec918dba959ff16b1242a9bc064f58d7799bb33432d9a3c988b7b52457a"
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

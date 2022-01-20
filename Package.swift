// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
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
                url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.3.1/FBAEMKit-Static_XCFramework.zip",
                checksum: "3ec0add385cfb6f8fee6ec1a6b87e14d8acb12bd7a52ff86717384b5fbc94b20"
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
                url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.3.1/FBSDKCoreKit_Basics-Static_XCFramework.zip",
                checksum: "d844db7fb9ebc7b11107062a7202741877a641f7713c2e290ad90165b19571ea"
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
                url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.3.1/FBSDKCoreKit-Static_XCFramework.zip",
                checksum: "41b25386d988f15aaee2b518fd6f2217fe89de709d0b6d4f1a82d1a80a5ec7f5"
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
                url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.3.1/FBSDKLoginKit-Static_XCFramework.zip",
                checksum: "c2ab6467bde31cfdbafdb970859da45f9f079ee9fbd591dc667ca75df4ce869d"
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
                url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.3.1/FBSDKShareKit-Static_XCFramework.zip",
                checksum: "2459ff510766894a718bf2bb5c1507bff07d020f030020b886fb864a50b154f1"
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
                url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.3.1/FacebookGamingServices-Static_XCFramework.zip",
                checksum: "5ba91a51c7a35185188ed53958ac34882cc389b492a1eee732d4d5896dd2cda6"
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
                url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.3.1/FBSDKGamingServicesKit-Static_XCFramework.zip",
                checksum: "e40b1aa4169955d52d2c2ee799e39979fdca5cd3768737c806d330b20e2670df"
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

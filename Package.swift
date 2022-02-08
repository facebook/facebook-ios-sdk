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
                url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.3.2/FBAEMKit-Static_XCFramework.zip",
                checksum: "3b4fec4cf27fc4333c20878915d325242422efe6e9ac72856e62252b6e4fd6fc"
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
                url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.3.2/FBSDKCoreKit_Basics-Static_XCFramework.zip",
                checksum: "9264d58da6047677d3b1a7c60936f7146be0a6fc1ae54e98037db90f74448366"
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
                url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.3.2/FBSDKCoreKit-Static_XCFramework.zip",
                checksum: "fdc6d084d0a5e4bc9e8504dce6804d3fe0a62ac26336d29dd2578a76f2d94826"
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
                url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.3.2/FBSDKLoginKit-Static_XCFramework.zip",
                checksum: "fd8d07dd34e6bae89a36f1f549a5fa852809756a02ede837f435f9aff13d9640"
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
                url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.3.2/FBSDKShareKit-Static_XCFramework.zip",
                checksum: "f00564fe1fabb3deef0c00995c7cdc1b3d82b4ebfad6849fd2bb3443297779e8"
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
                url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.3.2/FacebookGamingServices-Static_XCFramework.zip",
                checksum: "9302a951cf25d4d22a886c4f9b14ae0a16062abe7af48795332debd9a3edffec"
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
                url: "https://github.com/facebook/facebook-ios-sdk/releases/download/v12.3.2/FBSDKGamingServicesKit-Static_XCFramework.zip",
                checksum: "2b54ac2e083c2277de19bb90e8524ca33b371834a2484783afac9fe635d5b694"
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

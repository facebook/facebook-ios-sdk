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

let package = Package(
    name: "Facebook",
    platforms: [
        .iOS(.v11),
        .tvOS(.v11)
    ],
    products: [
        // The Kernel of the SDK. Must be included as a runtime dependency.
        .basics,

        // The Facebook AEM Kit
        .aem,

        /*
          The Core SDK library that provides two importable modules:

            - FacebookCore which includes the most current interface and
              will contain interfaces for new features written in Swift

            - FBSDKCoreKit which contains legacy Objective-C interfaces
              that will be used to maintain backwards compatibility with
              types that have been converted to Swift.
              This will not contain interfaces for new features written in Swift.
         */
        .core,

        // The Facebook Login SDK
        .login,

        // The Facebook Share SDK
        .share,

        // The Facebook Gaming Services SDK
        .gaming,

        // The Facebook tvOS SDK.
        .tv,
    ],
    targets: [
        // The kernel of the SDK
        .Prefixed.basics,

        /*
          The legacy Objective-C implementation that will be converted to Swift.
          This will not contain interfaces for new features written in Swift.
        */
        .Prefixed.aem,

        // The main AEM module
        .aem,

        /*
          The legacy Objective-C implementation that will be converted to Swift.
          This will not contain interfaces for new features written in Swift.
        */
        .Prefixed.core,

        // The main Core SDK module
        .core,

        /*
          The legacy Objective-C implementation that will be converted to Swift.
          This will not contain interfaces for new features written in Swift.
        */
        .Prefixed.login,

        // The main Login SDK module
        .login,

        /*
          The legacy Objective-C implementation that has been converted to Swift.
          This will not contain interfaces for new features written in Swift.
        */
        .Prefixed.share,

        // The main Share SDK module
        .share,

        /*
          The legacy Objective-C implementation that has been converted to Swift.
          This will not contain interfaces for new features written in Swift.
        */
        .Prefixed.gamingServices,

        // The main Facebook Gaming Services module
        .gaming,

        // The tvOS-specific SDK with an FBSDK-prefixed name.
        .Prefixed.tv,

        // The tvOS-specific SDK.
        .tv,
    ],
    cxxLanguageStandard: .cxx11
)

extension Product {
    static let basics = library(name: .basics, targets: [.Prefixed.basics])
    static let core = library(name: .core, targets: [.core, .Prefixed.core])
    static let login = library(name: .login, targets: [.login])
    static let share = library(name: .share, targets: [.share, .Prefixed.share])
    static let gaming = library(name: .gaming, targets: [.gaming, .Prefixed.gaming])
    static let aem = library(name: .aem, targets: [.aem, .Prefixed.aem])
    static let tv = library(name: .tv, targets: [.tv])
}

extension Target {
    static let binarySource = BinarySource()

    static func binaryTarget(name: String, remoteChecksum: String) -> Target {
        switch binarySource {
        case .local:
            return .binaryTarget(
                name: name,
                path: localBinaryPath(for: name)
            )
        case .remote:
            return .binaryTarget(
                name: name,
                url: remoteBinaryURLString(for: name),
                checksum: remoteChecksum
            )
        }
    }

    static func localBinaryPath(for targetName: String) -> String {
        "build/XCFrameworks/Static/\(targetName).xcframework"
    }

    static func remoteBinaryURLString(for targetName: String) -> String {
        "https://github.com/facebook/facebook-ios-sdk/releases/download/v14.0.0/\(targetName)-Static_XCFramework.zip"
    }

    static let aem = target(name: .aem, dependencies: [.Prefixed.aem])

    static let core = target(
        name: .core,
        dependencies: [.aem, .Prefixed.basics, .Prefixed.core],
        linkerSettings: [
            .cPlusPlusLibrary,
            .zLibrary,
            .accelerateFramework,
        ]
    )

    static let login = target(name: .login, dependencies: [.core, .Prefixed.login])

    static let share = target(name: .share, dependencies: [.core, .Prefixed.share])

    static let gaming = target(name: .gaming, dependencies: [.Prefixed.gaming])

    static let tv = target(name: .tv, dependencies: [.Prefixed.tv])

    enum Prefixed {
        static let basics = binaryTarget(
            name: .Prefixed.basics,
            remoteChecksum: "0c46ab4fe339da87b7e45d22276800953a9429d2562fb9b54835b860385c0f07"
        )

        static let aem = binaryTarget(
            name: .Prefixed.aem,
            remoteChecksum: "694fe8857e21d5208ac382879416eed1d291c6703f94d63099d38b8f3317019a"
        )

        static let core = binaryTarget(
            name: .Prefixed.core,
            remoteChecksum: "452444279282443ba7350323fda093259ffd17550ddfc5687f5e423ed2e1cb30"
        )

        static let login = binaryTarget(
            name: .Prefixed.login,
            remoteChecksum: "50bfb9a317d96ef9bc26a587190216c25a922f46d64de8d2e4aca8d43753a242"
        )

        static let share = binaryTarget(
            name: .Prefixed.share,
            remoteChecksum: "6da59633f039c41dfd6d89adb0c20d22d86333410c0e78613a0ae6f30c131cea"
        )

        static let gamingServices = binaryTarget(
            name: .Prefixed.gaming,
            remoteChecksum: "bc7d64539f992c10a771fa83727b9dab5181d999a0541ec8afd39070ac88c101"
        )

        static let tv = binaryTarget(
            name: .Prefixed.tv,
            remoteChecksum: "cc8a40192a7773ab96fbdbb42995ee8168100ea5f37650940e3c3bdc49886680"
        )
    }
}

extension Target.Dependency {
    static let aem = byName(name: .aem)
    static let core = byName(name: .core)

    enum Prefixed {
        static let aem = byName(name: .Prefixed.aem)
        static let basics = byName(name: .Prefixed.basics)
        static let core = byName(name: .Prefixed.core)
        static let login = byName(name: .Prefixed.login)
        static let share = byName(name: .Prefixed.share)
        static let gaming = byName(name: .Prefixed.gaming)
        static let tv = byName(name: .Prefixed.tv)
    }
}

extension LinkerSetting {
    static let cPlusPlusLibrary = linkedLibrary("c++")
    static let zLibrary = linkedLibrary("z")
    static let accelerateFramework = linkedFramework("Accelerate")
}

enum BinarySource {
    case local, remote

    init() {
        if getenv("USE_LOCAL_FB_BINARIES") != nil {
            self = .local
        } else {
            self = .remote
        }
    }
}

extension String {
    static let aem = "FacebookAEM"
    static let basics = "FacebookBasics"
    static let core = "FacebookCore"
    static let login = "FacebookLogin"
    static let share = "FacebookShare"
    static let gaming = "FacebookGamingServices"
    static let tv = "FacebookTV"

    enum Prefixed {
        static let aem = "FBAEMKit"
        static let basics = "FBSDKCoreKit_Basics"
        static let core = "FBSDKCoreKit"
        static let login = "FBSDKLoginKit"
        static let share = "FBSDKShareKit"
        static let gaming = "FBSDKGamingServicesKit"
        static let tv = "FBSDKTVOSKit"
    }
}

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
    platforms: [.iOS(.v12)],
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
        "https://github.com/facebook/facebook-ios-sdk/releases/download/v16.1.0/\(targetName)-Static_XCFramework.zip"
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

    enum Prefixed {
        static let basics = binaryTarget(
            name: .Prefixed.basics,
            remoteChecksum: "e7aaeb3afb1376894250a53b8027e0f4fdace9cbe64266d8ca4876d335efecc7"
        )

        static let aem = binaryTarget(
            name: .Prefixed.aem,
            remoteChecksum: "7157fa86958515c70a0f28822f00af0137b3be20f2c7dfdd5658d9c69baee2b3"
        )

        static let core = binaryTarget(
            name: .Prefixed.core,
            remoteChecksum: "f68e0dadf63e089019f55f6f41a8ae76a87afb753d5b53221346d527ed064864"
        )

        static let login = binaryTarget(
            name: .Prefixed.login,
            remoteChecksum: "1e4df5248427adfd72ffa3db3c7b5cfeae4cc03cad5ee59c497cd080efe0d238"
        )

        static let share = binaryTarget(
            name: .Prefixed.share,
            remoteChecksum: "638b4468f2a287eb443cff284aaf9dbfa4b23e3e73e07079124cba47334a8f5c"
        )

        static let gamingServices = binaryTarget(
            name: .Prefixed.gaming,
            remoteChecksum: "5d35a2aff9128954125bdc210e96fd0a7278e4e95850cd7a676cb7bae855c9ab"
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

    enum Prefixed {
        static let aem = "FBAEMKit"
        static let basics = "FBSDKCoreKit_Basics"
        static let core = "FBSDKCoreKit"
        static let login = "FBSDKLoginKit"
        static let share = "FBSDKShareKit"
        static let gaming = "FBSDKGamingServicesKit"
    }
}

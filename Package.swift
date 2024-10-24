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
        .basics,

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
    static let basics = library(name: .basics, targets: [.basics, .Prefixed.basics])
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
        "build/XCFrameworks/Dynamic/\(targetName).xcframework"
    }

    static func remoteBinaryURLString(for targetName: String) -> String {
        "https://github.com/facebook/facebook-ios-sdk/releases/download/v17.4.0/\(targetName)-Dynamic_XCFramework.zip"
    }

    static let basics = target(
        name: .basics,
        dependencies: [.Prefixed.basics],
        resources: [
           .copy("Resources/PrivacyInfo.xcprivacy"),
        ]
    )

    static let aem = target(
        name: .aem,
        dependencies: [.Prefixed.aem],
        resources: [
           .copy("Resources/PrivacyInfo.xcprivacy"),
        ]
    )

    static let core = target(
        name: .core,
        dependencies: [.aem, .Prefixed.basics, .Prefixed.core],
        resources: [
           .copy("Resources/PrivacyInfo.xcprivacy"),
        ],
        linkerSettings: [
            .cPlusPlusLibrary,
            .zLibrary,
            .accelerateFramework,
        ]
    )

    static let login = target(
        name: .login,
        dependencies: [.core, .Prefixed.login],
        resources: [
            .copy("Resources/PrivacyInfo.xcprivacy"),
        ]
    )

    static let share = target(
        name: .share,
        dependencies: [.core, .Prefixed.share],
        resources: [
           .copy("Resources/PrivacyInfo.xcprivacy"),
        ]
    )

    static let gaming = target(name: .gaming, dependencies: [.core, .Prefixed.share, .Prefixed.gaming])

    enum Prefixed {
        static let basics = binaryTarget(
            name: .Prefixed.basics,
            remoteChecksum: "1acb91f34e889975828cc06cffd081b39aec56eca5a485d8c25530e66afd4f6c"
        )

        static let aem = binaryTarget(
            name: .Prefixed.aem,
            remoteChecksum: "339b1b98c3df1347858cc57512ea2d69e499885196b5b7475d012844ca2f97b4"
        )

        static let core = binaryTarget(
            name: .Prefixed.core,
            remoteChecksum: "e83b30c6f6889228d1f104f97e803464b447bfbfdd167586ce97b695855a07ac"
        )

        static let login = binaryTarget(
            name: .Prefixed.login,
            remoteChecksum: "933243be923b01656eecf3cb8db46a8fbc9ed8a1af621fda9aa202b00f62d201"
        )

        static let share = binaryTarget(
            name: .Prefixed.share,
            remoteChecksum: "d4ff37b80e3ac8f5d2b096b35bb05dfbf93e6f2cbf477017816a0ec203a0d283"
        )

        static let gamingServices = binaryTarget(
            name: .Prefixed.gaming,
            remoteChecksum: "7750749a4280e7d37ab6f0b3ab8552137a3804c341e1a9f319729828d973455c"
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

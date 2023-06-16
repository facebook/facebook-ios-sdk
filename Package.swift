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
        "https://github.com/facebook/facebook-ios-sdk/releases/download/v16.1.1/\(targetName)-Static_XCFramework.zip"
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
            remoteChecksum: "e404d448e1885cc05342319eb0f05f264dc07889af5e66396c1573189e5587a1"
        )

        static let aem = binaryTarget(
            name: .Prefixed.aem,
            remoteChecksum: "6f3bfe4378c6b27a84c36114cf22e342b3119f35abce5cd7834dc89e43156500"
        )

        static let core = binaryTarget(
            name: .Prefixed.core,
            remoteChecksum: "d9032ad53b1ce4585e766efa6caf84de0ed1c478942ae27ac074a2c9679e4e08"
        )

        static let login = binaryTarget(
            name: .Prefixed.login,
            remoteChecksum: "39b9a588d7b162e86335bb43187df3c4259c99730c909b0bf9f22f6425366c9f"
        )

        static let share = binaryTarget(
            name: .Prefixed.share,
            remoteChecksum: "71dc7f2d2392d94b2dc6e5022a72663e11f0ce101e772af9cd56c5520e885b4e"
        )

        static let gamingServices = binaryTarget(
            name: .Prefixed.gaming,
            remoteChecksum: "406326489d0d7c8af0ac5f1bdb45188e73e3bdda2a6a81d632088a6a4a8dd895"
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

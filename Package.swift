// swift-tools-version:5.3

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
        .basics,
        .core,
    ],
    targets: [
        .Prefixed.basics,
        .basics,
        .Prefixed.core,
        .core,
    ],
    cxxLanguageStandard: .cxx11
)

extension Product {
    static let basics = library(name: .basics, targets: [.basics, .Prefixed.basics])
    static let core = library(name: .core, targets: [.core, .Prefixed.core])
}

extension Target {
    static let basics = target(
        name: .basics,
        dependencies: [.Prefixed.basics],
        resources: [
            .copy("Resources/PrivacyInfo.xcprivacy"),
        ]
    )

    static let core = target(
        name: .core,
        dependencies: [.basics, .Prefixed.core],
        resources: [
            .copy("Resources/PrivacyInfo.xcprivacy"),
        ],
        linkerSettings: [
            .cPlusPlusLibrary,
            .zLibrary,
            .accelerateFramework,
        ]
    )

    enum Prefixed {
        static let basics = binaryTarget(
            name: .Prefixed.basics,
            remoteChecksum: "750f129c7413d51dfdeca1cc983743996fbf28154d80b2434acee7d537d64179"
        )

        static let core = binaryTarget(
            name: .Prefixed.core,
            remoteChecksum: "6d78eb5ad74812c8a45921b98824590fb0ad013c0afe7fc42f58fb7a48b17cd4"
        )
    }
}

extension Target.Dependency {
    static let core = byName(name: .core)

    enum Prefixed {
        static let basics = byName(name: .Prefixed.basics)
        static let core = byName(name: .Prefixed.core)
    }
}

extension LinkerSetting {
    static let cPlusPlusLibrary = linkedLibrary("c++")
    static let zLibrary = linkedLibrary("z")
    static let accelerateFramework = linkedFramework("Accelerate")
}

extension String {
    static let basics = "FacebookBasics"
    static let core = "FacebookCore"

    enum Prefixed {
        static let basics = "FBSDKCoreKit_Basics"
        static let core = "FBSDKCoreKit"
    }
}


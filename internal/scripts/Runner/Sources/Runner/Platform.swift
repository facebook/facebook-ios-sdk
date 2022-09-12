// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation

enum Platform: CaseIterable {
    case iOS
//    TODO: Uncomment for release
//    case tvOS

    var buildDirectory: Directory {
        switch self {
        case .iOS: return .build
//        case .tvOS: return .tv
        }
    }

    var schemeSuffix: String {
        switch self {
        case .iOS: return ""
//        TODO: Uncomment for release
//        case .tvOS: return "_TV"
        }
    }

    var supportedArchitectures: [Architecture] {
        switch self {
        case .iOS: return [.arm64, .armv7, .x86_64]
//        TODO: Uncomment for release
//        case .tvOS: return [.arm64, .x86_64]
        }
    }

    var products: [Product] {
        switch self {
        case .iOS:
            return [
                .basics,
                .core,
                .login,
                .share,
                .gamingServices,
            ]
//        TODO: Uncomment for release
//        case .tvOS:
//            return [
//                .basics,
//                .core,
//                .login,
//                .share,
//                .tvoskit
//            ]
        }
    }
}

enum Architecture: String, CaseIterable {
    case arm64
    case armv7
    case x86_64 // swiftlint:disable:this identifier_name
}

struct Destination {
    let name: String
    let sdk: String?
    let archiveToken: String
    let platform: Platform

//    TODO: Uncomment for release
//    static let tvos = Destination(
//        name: "generic/platform=tvOS",
//        sdk: "appletvos",
//        archiveToken: "tvos",
//        platform: .tvOS
//    )
//    static let tvosSimulator = Destination(
//        name: "generic/platform=tvOS Simulator",
//        sdk: "appletvsimulator",
//        archiveToken: "tvos-simulator",
//        platform: .tvOS
//    )
    static let ios = Destination(
        name: "generic/platform=iOS",
        sdk: "iphoneos",
        archiveToken: "ios",
        platform: .iOS
    )
    static let iosSimulator = Destination(
        name: "generic/platform=iOS Simulator",
        sdk: "iphonesimulator",
        archiveToken: "ios-simulator",
        platform: .iOS
    )
    static let macCatalyst = Destination(
        name: "generic/platform=macOS,variant=Mac Catalyst",
        sdk: nil,
        archiveToken: "mac-catalyst",
        platform: .iOS
    )

    func schemeSuffix(libraryType: LibraryType) -> String {
        platform.schemeSuffix + "-\(libraryType.rawValue.capitalized)"
    }
}

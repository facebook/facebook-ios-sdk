// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation

enum Platform: CaseIterable {
    case iOS

    var buildDirectory: Directory {
        switch self {
        case .iOS: return .build
        }
    }

    var schemeSuffix: String {
        switch self {
        case .iOS: return ""
        }
    }

    var supportedArchitectures: [Architecture] {
        switch self {
        case .iOS: return [.arm64, .armv7, .x86_64]
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

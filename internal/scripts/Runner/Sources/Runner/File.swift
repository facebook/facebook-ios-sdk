// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation

enum File {
    enum Name {
        case buck
        case coreKitVersions
        case error
        case everstoreHandle
        case hackbookIPA
        case output
        case packageManifest
        case podspec(String)
        case zip(String)

        var rawValue: String {
            switch self {
            case .buck: return "BUCK"
            case .coreKitVersions: return "FBSDKCoreKitVersions.h"
            case .error: return "error.txt"
            case .everstoreHandle: return "everstoreHandle.txt"
            case .hackbookIPA: return "Hackbook.ipa"
            case .output: return "output.txt"
            case .packageManifest: return "Package.swift"
            case let .podspec(name): return "\(name).podspec"
            case let .zip(version): return "\(version).zip"
            }
        }
    }

    static func path(for fileName: Name, inDirectory directory: Directory) -> String {
        url(for: fileName, inDirectory: directory).relativePath
    }

    static func url(for fileName: Name, inDirectory directory: Directory) -> URL {
        directory.url.appendingPathComponent(fileName.rawValue)
    }
}

// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import ArgumentParser
import Foundation
import ShellOut

/// This is the release step to build a zip file supporting Carthage and CocoaPods
struct ZipXCFrameworks: ParsableCommand {
    enum Name {
        static let dynamic = "FacebookSDK_Dynamic.xcframework.zip"
        static let `static` = "FacebookSDK-Static_XCFramework.zip"
    }

    static var configuration = CommandConfiguration(commandName: "zip-dynamic-xcframeworks")

    @Option(
        name: .customLong("linking"),
        help: """
            The library format to create a zip directory for. Valid options include [static, dynamic].
            Defaults to dynamic.
            """
    )
    var libraryType = LibraryType.dynamic

    var name: String {
        switch libraryType {
        case .dynamic: return Name.dynamic
        case .static: return Name.static
        }
    }

    mutating func run() throws {
        switch libraryType {
        case .dynamic:
            try FileSystem.execute(from: .xcframeworks) {
                try shellOut(to: "mv Dynamic XCFrameworks") // Workaround to have the "Dynamic" folder unzip to "XCFrameworks"
                try shellOut(to: "ditto -c -k --sequesterRsrc --keepParent XCFrameworks \(Name.dynamic)")
                try shellOut(to: "mv XCFrameworks Dynamic") // Undo the above rename
            }
        case .static:
            try FileSystem.execute(from: .xcframeworks) {
                try shellOut(to: "mv Static XCFrameworks") // Workaround to have the "Static" folder unzip to "XCFrameworks"
                try shellOut(to: "ditto -c -k --sequesterRsrc --keepParent XCFrameworks \(Name.static)")
                try shellOut(to: "mv XCFrameworks Static") // Undo the above rename
            }
        }
    }
}

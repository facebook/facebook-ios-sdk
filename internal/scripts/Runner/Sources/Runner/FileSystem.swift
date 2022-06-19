// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation
import ShellOut

enum FileSystem {

    @discardableResult
    static func execute<Output>(from directory: Directory, closure: () throws -> Output) throws -> Output {
        let startingPath = try shellOut(to: "pwd")
        setCurrentDirectory(directory)
        let output = try closure()
        setCurrentDirectory(startingPath)
        return output
    }

    static func copy(_ directory: Directory, to destination: Directory) throws {
        try FileManager.default.copyItem(at: directory.url, to: destination.url)
    }

    static func move(_ directory: Directory, to destination: Directory) throws {
        try FileManager.default.moveItem(at: directory.url, to: destination.url)
    }

    /// Do not call directly. If you need to execute code from another directory, use `execute(from:closure:)`
    private static func setCurrentDirectory(_ directory: Directory) {
        setCurrentDirectory(directory.path)
    }

    /// Do not call directly. If you need to execute code from another directory, use `execute(from:closure:)`
    private static func setCurrentDirectory(_ path: String) {
        guard FileManager.default.changeCurrentDirectoryPath(path) else {
            print("Failed to change current directory to: \(path)")
            exit(1)
        }
    }
}

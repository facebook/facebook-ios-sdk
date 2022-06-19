// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import ArgumentParser
import Foundation
import Mustache
import ShellOut

struct PrepareRelease: ParsableCommand {

    static var configuration = CommandConfiguration(
        abstract: """
        Prepares static and dynamically linked XCFramework artifacts for release.
        Builds and zips XCFrameworks for uploading to the release.
        Updates Podspecs and the Swift Package Manifest for the release.
        """
    )

    mutating func run() throws {
        removeDirectory(Directory.build)
        Build.main(["xcframeworks", "--linking", "static"])
        Build.main(["xcframeworks", "--linking", "dynamic"])
        ZipXCFrameworks.main(["--linking", "static"])
        ZipXCFrameworks.main(["--linking", "dynamic"])
        GeneratePodspecs.main([])
        GeneratePackageManifest.main([])
    }

    private func removeDirectory(_ directory: Directory) {
        do {
            print("Deleting: \(directory.url)")
            try FileManager.default.removeItem(at: directory.url)
        } catch {
            print("Unable to delete \(directory.url), Error: \(error.localizedDescription)")
        }
    }
}

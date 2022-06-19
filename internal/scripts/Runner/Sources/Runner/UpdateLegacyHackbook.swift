// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import ArgumentParser
import Foundation
import ShellOut

struct UpdateLegacyHackbook: ParsableCommand {

    @Flag(name: .customLong("cleanup"), inversion: .prefixedNo, help: "Whether to clean the file directory after running. Defaults to true.")
    var shouldCleanup = true

    @Flag(name: .customLong("upload"), inversion: .prefixedNo, help: "Whether to upload to everstore")
    var shouldUploadIPA = true

    @Flag(name: .customLong("sandcastle"), help: "Whether or not the job is running on Sandcastle")
    var isSandcastle = false

    @Flag(name: .customLong("use-current-version"), inversion: .prefixedNo, help: "Whether to check for a new version or use the current version")
    var shouldUseCurrentVersion = false

    mutating func run() throws {
        defer { shouldCleanup ? try? cleanup() : nil }

        let version = try Versioning.extract(useCurrentVersion: shouldUseCurrentVersion)

        try generateProjects()
        try buildReleaseForVendorLib(version)
        try updateLegacyBuildFiles(for: version, type: .sdk)
        try updateLegacyBuildFiles(for: version, type: .hackbook)
        try buildHackbookIPA(for: version)
        try uploadIPA(for: version)
    }

    // MARK: - Private Methods

    private func cleanup() throws {
        print("Cleaning up generated and modified files...")

        try FileSystem.execute(from: .sdk) {
            let version = try Versioning.extract(useCurrentVersion: shouldUseCurrentVersion)
            try shellOut(to: "hg revert \(File.path(for: .buck, inDirectory: .hackbook))")
            try shellOut(to: "hg revert \(File.path(for: .buck, inDirectory: .vendoredFacebookSDK))")
            try FileManager.default.removeItem(at: File.url(for: .zip(version), inDirectory: .vendoredFacebookSDK))
            try FileManager.default.removeItem(at: File.url(for: .ipa(version), inDirectory: .home))
            try FileManager.default.removeItem(
                at: File.url(for: .everstoreHandle, inDirectory: isSandcastle ? .box : .sdk)
            )
        }
    }

    private func generateProjects() throws {
        print("Generating Xcode Projects")

        try FileSystem.execute(from: .internalScripts) {
            try shellOut(to: "./generate-projects.sh")
        }
    }

    private func uploadIPA(for version: String) throws {
        if shouldUploadIPA {
            print("Uploading ipa to everstore...")
            let outputDirectory = isSandcastle ? Directory.box : .sdk
            let handleURL = File.url(for: .everstoreHandle, inDirectory: outputDirectory)

            // This is strange. The command `arc everstore store` returns the file handle correctly but
            // outputs a non-zero code. The only way to get the handle is to provide a file handle to
            // write the error to. So creating a file to write the error to.
            try FileSystem.execute(from: outputDirectory) {
                try shellOut(to: "touch \(handleURL.lastPathComponent)")
            }

            try shellOut(
                to: "arc everstore store --bucket 12015 $HOME/\(File.Name.ipa(version).rawValue) --handle-only",
                errorHandle: FileHandle(forUpdating: handleURL)
            )

            guard let handle = try? String(contentsOf: handleURL, encoding: .utf8),
                !handle.isEmpty
            else {
                throw Error.missingEverstoreHandle
            }

            print("Uploaded ipa to everstore.")
            print("\(version) \(handle)")
        }
    }

    private func buildHackbookIPA(for version: String) throws {
        print("Building Hackbook IPA for v\(version)...")
        try shellOut(to: "buck build //fbobjc/ios-sdk/internal/testing/Hackbook:Hackbook.\(version)Package --out $HOME")
    }

    private func buildReleaseForVendorLib(_ version: String) throws {
        print("Cleaning build directory...")
        removeDirectory(.xcodeBuildDir)
        try FileSystem.execute(from: .sdk) {
            print("Building SDK v\(version) with Release configuration")
            try shellOut(to: buildForReleaseCommandLine.commandLineString)
        }
        try FileSystem.execute(from: .releaseSimulator) {
            try shellOut(to: "zip -r \(version).zip ./*.framework ./*/*.framework")
            try moveRelease(version: version, to: .vendoredFacebookSDK)
        }
    }

    private var buildForReleaseCommandLine: CommandLine {
        CommandLine(
            command: "xcodebuild",
            action: "build",
            options: [
                CommandLine.Option(name: "-workspace", arguments: ["FacebookSDK.xcworkspace"]),
                CommandLine.Option(name: "-scheme", arguments: ["BuildAllKits-Static"]),
                CommandLine.Option(name: "-configuration", arguments: ["Release"]),
                CommandLine.Option(name: "-sdk", arguments: ["iphonesimulator"]),
            ],
            arguments: [],
            environmentVariables: [
                CommandLine.EnvironmentVariable(name: "BUILD_DIR", value: Directory.xcodeBuildDir.url.path),
            ]
        )
    }

    private func moveRelease(version: String, to directory: Directory) throws {
        try FileManager.default.moveItem(
            at: Directory.releaseSimulator.url.appendingPathComponent("\(version).zip"),
            to: directory.url.appendingPathComponent("\(version).zip")
        )
    }

    private func removeDirectory(_ directory: Directory) {
        try? FileManager.default.removeItem(at: directory.url)
    }

    private enum BuildRecipe {
        case hackbook
        case sdk
    }

    private func updateLegacyBuildFiles(for version: String, type: BuildRecipe) throws {
        switch type {
        case .hackbook:
            let url = File.url(for: .buck, inDirectory: .hackbook)
            try """
            load("@fbsource//fbobjc/EndToEndTests/Tests/FacebookSDK:DEFS.bzl", "legacy_hackbook")
            \(String(contentsOf: url))

            legacy_hackbook(
                config = HACKBOOK_CONFIG,
                version = "\(version)",
            )
            """
                .write(to: url, atomically: false, encoding: .utf8)

        case .sdk:
            let url = File.url(for: .buck, inDirectory: .vendoredFacebookSDK)
            try """
            load("@fbsource//fbobjc/EndToEndTests/Tests/FacebookSDK:DEFS.bzl", "fb_sdk_library")
            \(String(contentsOf: url))

            fb_sdk_library(version = "\(version)")
            """
                .write(to: url, atomically: false, encoding: .utf8)
        }
    }
}

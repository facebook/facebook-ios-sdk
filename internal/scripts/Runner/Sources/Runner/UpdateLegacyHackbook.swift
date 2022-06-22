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
        try buildHackbookIPA(for: version)
        try uploadIPA(for: version)
    }

    // MARK: - Private Methods

    private func cleanup() throws {
        print("Cleaning up generated and modified files...")

        try FileSystem.execute(from: .sdk) {
            try FileManager.default.removeItem(at: File.url(for: .hackbookIPA, inDirectory: .hackbook))
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
        try FileSystem.execute(from: .hackbook) {
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

            try FileSystem.execute(from: .fbsource(isSandcastle: isSandcastle)) {
                try shellOut(
                    to: "arc everstore store --bucket 12015 \(Directory.hackbook.path)/build/Hackbook.ipa --handle-only",
                    errorHandle: FileHandle(forUpdating: handleURL)
                )
            }

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

        let command = CommandLine(
            command: "xcodebuild",
            action: "build",
            options: [
                CommandLine.Option(name: "-project", arguments: ["Hackbook.xcodeproj"]),
                CommandLine.Option(name: "-scheme", arguments: ["Hackbook"]),
                CommandLine.Option(name: "-derivedDataPath", arguments: ["build"]),
                CommandLine.Option(name: "-configuration", arguments: ["Debug"]),
                CommandLine.Option(name: "-sdk", arguments: ["iphonesimulator"]),
            ],
            arguments: [],
            environmentVariables: []
        )
        try FileSystem.execute(from: .hackbook) {
            try shellOut(to: command.commandLineString)
            try shellOut(to: "mkdir -p build/Hackbook/Payload")
            try shellOut(to: "mv build/Build/Products/Debug-iphonesimulator/Hackbook.app build/Hackbook/Payload")
            try shellOut(to: "cd build && zip -r Hackbook.ipa Hackbook")
        }
    }
}

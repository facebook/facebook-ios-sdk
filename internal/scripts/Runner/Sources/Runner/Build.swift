// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import ArgumentParser
import Foundation
import ShellOut

struct Build: ParsableCommand {

    enum BuildType: String, ExpressibleByArgument {
        case xcframeworks
    }

    @Argument(help: "The type of build to produce. Valid options include [xcframeworks]")
    var type: BuildType

    @Option(
        name: .customLong("linking"),
        help: """
            The library format to produce. Valid options include [static, dynamic].
            Only applies to the xcframeworks build type. Defaults to dynamic.
            """
    )
    var libraryType = LibraryType.dynamic

    @Option(
        name: .shortAndLong,
        parsing: .upToNextOption,
        help: """
            The list of products to build.
            Accepts some variation in casing and prefixing
            example usage: `-p aem core LoginKit FBSDKShareKit
            """
    )
    var products = Product.allCases

    private static let outputPath = File.path(for: .output, inDirectory: .box)
    private static let errorPath = File.path(for: .error, inDirectory: .box)

    mutating func run() throws {
        switch type {
        case .xcframeworks:
            try buildXCFrameworks()
        }
    }

    // MARK: - Private Methods

    private func generateProjects() throws {
        print("Generating Xcode Projects")

        try FileSystem.execute(from: .internalScripts) {
            try shellOut(to: "./generate-projects.sh")
        }
    }

    private func buildXCFrameworks() throws {
        try generateProjects()
        try produceFrameworks()

        // Fix for https://github.com/facebook/facebook-ios-sdk/issues/2004
        // We should only be modifying slices for SPM users
        if libraryType == .static {
            // Fix for https://github.com/facebook/facebook-ios-sdk/issues/1907
            // SPM requires an incorrect directory structure within Catalyst frameworks
            try fixStaticCatalystSlice()
        }
    }

    private func produceFrameworks() throws {
        try products.forEach { product in
            let archives = try buildXCArchives(for: product)

            try buildXCFramework(for: product, from: archives)
        }
    }

    private func buildXCArchives(for product: Product) throws -> [Archive] {
        try product.destinations.map { destination in
            print("Building XCArchive with destination: \(destination)")

            let sdk = destination.sdk
            let url = Directory.build.url
                .appendingPathComponent("Archives/\(libraryType.rawValue.capitalized)/\(product.rawValue)-\(destination.archiveToken)")

            return try archive(
                product: product,
                destination: destination,
                sdk: sdk,
                url: url
            )
        }
    }

    // Fix for https://github.com/facebook/facebook-ios-sdk/issues/1907
    //
    // This is to work around what appears to be a bug in Xcode regarding how SPM resolves
    // binary targets with Catalyst.
    // A Catalyst project using the frameworks from SPM will generate a warning about inability
    // to resolve framework symlinks for the 'Versions' directory:
    // "Couldn't resolve framework symlink for ... /framework/Versions/Current): Invalid argument (22)"
    // and fail to sign the frameworks with: "code object is not signed at all"
    //
    // This only happens when the frameworks are provided by SPM, not manually, not with CocoaPods.
    // I figure this will be fixed in some future Xcode version and we can remove the workaround.
    private func fixStaticCatalystSlice() throws {
        try products
//    TODO: Uncomment for release
//            .filter { $0 != .tvoskit }
                .forEach { product in
                    try FileSystem.execute(from: .xcframeworks) {
                        let frameworkPath = "$PWD/\(libraryType.rawValue.capitalized)/\(product.rawValue).xcframework/ios-arm64_x86_64-maccatalyst/\(product.rawValue).framework"
                        try shellOut(to: "cd \(frameworkPath) && find . -type l -exec unlink {} \\;")
                        try shellOut(to: "cd \(frameworkPath) && cp -rp Versions/A/* .")
                        try shellOut(to: "rm -rf \(frameworkPath)/Versions")
                    }
                }
    }

    private func buildXCFramework(
        for product: Product,
        from archives: [Archive]
    ) throws {
        try FileSystem.execute(from: .sdk) {
            let frameworkOptions = try archives.flatMap {
                try $0.commandLineOptions()
            }
            let artifactPath = "\(Directory.xcframeworks.path)/\(libraryType.rawValue.capitalized)/\(product.rawValue).xcframework"

            let options = [CommandLine.Option(name: "-create-xcframework")] +
                frameworkOptions +
                [
                    CommandLine.Option(
                        name: "-output",
                        arguments: [artifactPath]
                    ),
                ]

            let buildCommand = CommandLine(
                command: "xcodebuild",
                action: nil,
                options: options,
                arguments: [],
                environmentVariables: []
            )

            print("BuildingXCFramework with command: \(buildCommand.commandLineString)")
            try shellOut(to: buildCommand.commandLineString)

            let licenseCommand = CommandLine(
                command: "cp",
                action: nil,
                options: [],
                arguments: ["LICENSE", artifactPath],
                environmentVariables: []
            )

            print("Copying LICENSE to \(artifactPath)")
            try shellOut(to: licenseCommand.commandLineString)
        }
    }

    /**
     Used for getting the path to the directory that the repo was cloned into.
     This is so that we can strip this directory from the debug cloning map and avoid bugs like:
     https://github.com/facebook/facebook-ios-sdk/issues/2091
     This will work for pathing as long as the repo has the name `facebook-ios-sdk`.
     */
    private func getPathToCloningDirectory() throws -> String {
        let path = try shellOut(to: "git rev-parse --show-toplevel")
        return path.replacingOccurrences(of: "/facebook-ios-sdk", with: "")
    }

    private func getSwiftDriverFlags() throws -> String {
        var flags = [String]()
        // Only use line-tables-only for static libraries
        if libraryType == .static {
            // Will ensure only enough information is generated to populate a stack trace
            flags.append("-gline-tables-only")
        }

        flags.append(
            // Maps the debug prefix map to be empty
            "-debug-prefix-map \(try getPathToCloningDirectory())="
        )

        return flags.joined(separator: " ")
    }

    private func getCDriverFlags() throws -> String {
        var flags = [String]()
        // Only use line-tables-only for static libraries
        if libraryType == .static {
            // Will ensure only enough information is generated to populate a stack trace
            flags.append("-gline-tables-only")
        }

        // Maps the debug prefix map and other file prefixes to be empty
        flags.append(
            "-ffile-prefix-map=\(try getPathToCloningDirectory())="
        )
        return flags.joined(separator: " ")
    }

    private func archive(
        product: Product,
        destination: Destination,
        sdk: String?,
        url: URL
    ) throws -> Archive {
        let options = [
            CommandLine.Option(name: "-workspace", arguments: ["FacebookSDK.xcworkspace"]),
            CommandLine.Option(name: "-scheme", arguments: [product.scheme(destination: destination, libraryType: libraryType)]),
            CommandLine.Option(name: "-destination", arguments: [destination.name]),
            sdk.flatMap { CommandLine.Option(name: "-sdk", arguments: [$0]) },
            CommandLine.Option(
                name: "-derivedDataPath",
                arguments: [Directory.build.url.standardizedFileURL.path]
            ),
            CommandLine.Option(name: "-archivePath", arguments: [url.standardizedFileURL.path]),
        ].compactMap { $0 }

        let frontendFlags = [
            "-Xfrontend -no-clang-module-breadcrumbs", // attempt to get rid of .pcm files
            "-Xfrontend -no-serialize-debugging-options",
        ].joined(separator: " ")

        let commandLine = CommandLine(
            command: "xcodebuild",
            action: "archive",
            options: options,
            arguments: [],
            environmentVariables: [
                CommandLine.EnvironmentVariable(name: "SWIFT_SERIALIZE_DEBUGGING_OPTIONS", value: "NO"),
                CommandLine.EnvironmentVariable(name: "SKIP_INSTALL", value: "NO"),
                CommandLine.EnvironmentVariable(
                    name: "OTHER_SWIFT_FLAGS",
                    value: "\"\(try getSwiftDriverFlags()) \(frontendFlags)\""
                ),
                CommandLine.EnvironmentVariable(
                    name: "OTHER_CFLAGS",
                    value: "\"\(try getCDriverFlags())\""
                ),
            ]
        )

        let archiveURL = url.appendingPathExtension("xcarchive")

        let archive: Archive = try FileSystem.execute(from: .sdk) {
            try shellOut(to: commandLine.commandLineString)
            return Archive(path: archiveURL, product: product, libraryType: libraryType)
        }

        try embedStringsBundleInArchive(ofProduct: product, atURL: archiveURL)

        return archive
    }

    private func embedStringsBundleInArchive(
        ofProduct product: Product,
        atURL url: URL
    ) throws {
        if let path = product.stringBundlePathInArchive(for: libraryType) {
            try FileSystem.execute(from: .sdk) {
                let copyCommand = "cp -R FacebookSDKStrings.bundle \(url.appendingPathComponent(path).path)"
                try shellOut(to: copyCommand)
            }
        }
    }

    private static func createFileHandles() throws -> ResultHandles {
        try shellOut(to: "touch \(Self.outputPath)")
        try shellOut(to: "touch \(Self.errorPath)")

        return ResultHandles(
            output: try FileHandle(forUpdating: File.url(for: .output, inDirectory: .box)),
            error: try FileHandle(forUpdating: File.url(for: .error, inDirectory: .box))
        )
    }

    private struct ResultHandles {
        let output: FileHandle
        let error: FileHandle
    }

    private struct Archive {
        let path: URL
        let product: Product
        let libraryType: LibraryType

        func commandLineOptions() throws -> [CommandLine.Option] {
            let symbolsOption = CommandLine.Option(
                name: "-debug-symbols",
                arguments: [
                    path
                        .appendingPathComponent("dSYMS/\(product.rawValue).framework.dSYM")
                        .standardizedFileURL.path,
                ]
            )
            let frameworkOption = CommandLine.Option(
                name: "-framework",
                arguments: [frameworkUrl.standardizedFileURL.path]
            )

            switch libraryType {
            case .dynamic:
                return [frameworkOption, symbolsOption]
            case .static:
                return [frameworkOption]
            }
        }

        private var frameworkUrl: URL {
            var url = path.appendingPathComponent("Products")

            switch libraryType {
            case .static:
                url.appendPathComponent("Library/Frameworks")
            case .dynamic:
                url.appendPathComponent("@rpath")
            }

            return url.appendingPathComponent("\(product.rawValue).framework")
        }

        private var dsymUrl: URL? {
            path.appendingPathComponent("dSYMS/\(product.rawValue).framework.dSYM")
        }
    }
}

// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation
import ShellOut

enum Versioning {
    private static var extractedLatest: String?

    static func extract(useCurrentVersion: Bool) throws -> String {
        if useCurrentVersion {
            return try extractCurrent()
        } else {
            return try extractUpdated()
        }
    }

    /// Returns the current version declared in FBSDKCoreKit.h
    private static func extractCurrent() throws -> String {
        try FileSystem.execute(from: .sdk) {
            guard let contents = try? String(contentsOf: File.url(for: .coreKitVersions, inDirectory: .include)) else {
                print("FBSDKCoreKitVersions.h not found.")
                Darwin.exit(1)
            }

            guard let regex = try? NSRegularExpression(pattern: "([0-9]{1}|[1-9][0-9]+)\\.([0-9]{1}|[1-9][0-9]+)\\.([0-9]{1}|[1-9][0-9]+)") else {
                print("Invalid regular expression")
                Darwin.exit(1)
            }
            let matches = regex.matches(
                in: contents,
                options: [],
                range: NSRange(location: 0, length: contents.utf8.count)
            )
            let versions = matches.compactMap {
                Range($0.range, in: contents).map { String(contents[$0]) }
            }
            guard let version = versions.first else {
                print("No valid version found in FBSDKCoreKitVersions.h.")
                Darwin.exit(1)
            }
            return version
        }
    }

    /// Checks if the version declared in FBSDKCoreKit.h is different between the current and previous commit.
    /// Returns the version if so. Otherwise exits with success.
    private static func extractUpdated() throws -> String {
        if let latest = extractedLatest {
            return latest
        }

        print("Checking FBSDKCoreKit.h for updated sdk version...")

        return try FileSystem.execute(from: .sdk) {
            let changes = try shellOut(
                to: "hg diff -c $( hg whereami ) FBSDKCoreKit/FBSDKCoreKit/include/FBSDKCoreKitVersions.h"
            )

            guard !changes.isEmpty else {
                print("There are no changes to FBSDKCoreKitVersions.h")
                Darwin.exit(0)
            }

            guard let regex = try? NSRegularExpression(pattern: "([0-9]{1}|[1-9][0-9]+)\\.([0-9]{1}|[1-9][0-9]+)\\.([0-9]{1}|[1-9][0-9]+)") else {
                print("Invalid regular expression")
                Darwin.exit(0)
            }

            let matches = regex.matches(
                in: changes,
                options: [],
                range: NSRange(location: 0, length: changes.utf8.count)
            )

            let versions = matches.compactMap {
                Range($0.range, in: changes).map { String(changes[$0]) }
            }

            guard versions.count == 2,
                  versions[0] != versions[1]
            else {
                print(
                    """
                    No updated SDK version found.

                    Full changeset:

                    \(changes)

                    Exiting. Goodbye.
                    """
                )
                Darwin.exit(0)
            }

            extractedLatest = versions[1]
            return versions[1]
        }
    }
}

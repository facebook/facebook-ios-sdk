// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import ArgumentParser
import Foundation
import ShellOut

struct Run: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Runs Commands",
        subcommands: [
            Build.self,
            GeneratePackageManifest.self,
            GeneratePodspecs.self,
            PrepareRelease.self,
            UpdateLegacyHackbook.self,
            ZipXCFrameworks.self
        ]
    )
}

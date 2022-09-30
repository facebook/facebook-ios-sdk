// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import ArgumentParser
import Foundation
import Mustache
import ShellOut

struct GeneratePodspecs: ParsableCommand {

    mutating func run() throws {
        try Product.allCases
//    TODO: Uncomment for release
//      .filter { $0 != .tvoskit }
                .forEach {
                    let repository = TemplateRepository(bundle: Bundle.module)
                    let template = try repository.template(named: "\($0.rawValue).podspec")

                    let content = [
                        "version": try Versioning.extract(useCurrentVersion: true),
                        "sha": try generateSha(),
                    ]

                    let podspec = try template.render(content)

                    try replacePodspec(named: $0.rawValue, contents: podspec)
                }
    }

    func generateSha() throws -> String {
        // This will succeed even if it cannot find anything to hash
        let sha = try FileSystem.execute(from: .xcframeworks) {
            try shellOut(to: "openssl sha1 -binary \(ZipXCFrameworks.Name.dynamic) | xxd -p")
        }

        guard !sha.isEmpty else { throw Error.podspecSHA1Generation }

        return sha
    }

    private func replacePodspec(named name: String, contents: String) throws {
        let url = File.url(for: .podspec(name), inDirectory: .sdk)
        try contents.write(to: url, atomically: false, encoding: .utf8)
    }
}

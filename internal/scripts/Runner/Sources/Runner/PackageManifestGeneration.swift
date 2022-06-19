// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import ArgumentParser
import Foundation
import Mustache
import ShellOut

struct GeneratePackageManifest: ParsableCommand {

    mutating func run() throws {
        // Load the `Package.swift.mustache` resource of the module bundle
        let repository = TemplateRepository(bundle: Bundle.module)
        let template = try repository.template(named: "Package.swift")

        // The content to use for filling out the template
        var content: [String: Any] = [
            "version": try Versioning.extract(useCurrentVersion: true)
        ]

        try Product.allCases.forEach { product in
            content[product.rawValue] = [
                "checksum": try generateChecksum(for: product)
            ]
        }
        let manifest = try template.render(content)

        try replacePackageManifest(with: manifest)
    }

    private func generateChecksum(for product: Product) throws -> String {
        try zipFramework(for: product)

        let zippedFrameworkName = "\(product.rawValue)-Static_XCFramework.zip"

        return try FileSystem.execute(from: .sdk) {
            try shellOut(to: "swift package compute-checksum build/\(zippedFrameworkName)")
        }
    }

    private func zipFramework(for product: Product) throws {
        try FileSystem.execute(from: .xcframeworks) {
            let source = "\(product.rawValue).xcframework"
            let destination = "../../\(product.rawValue)-Static_XCFramework.zip"
            try shellOut(to: "cd Static; zip -r \(destination) \(source)")
        }
    }

    private func replacePackageManifest(with manifest: String) throws {
        let url = File.url(for: .packageManifest, inDirectory: .sdk)
        try manifest.write(to: url, atomically: false, encoding: .utf8)
    }
}

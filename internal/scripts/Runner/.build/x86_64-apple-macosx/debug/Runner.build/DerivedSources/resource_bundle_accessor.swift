import class Foundation.Bundle

extension Foundation.Bundle {
    static var module: Bundle = {
        let mainPath = Bundle.main.bundleURL.appendingPathComponent("Runner_Runner.bundle").path
        let buildPath = "/Users/joesusnick/fbsource/fbobjc/ios-sdk/internal/scripts/Runner/.build/x86_64-apple-macosx/debug/Runner_Runner.bundle"

        let preferredBundle = Bundle(path: mainPath)

        guard let bundle = preferredBundle != nil ? preferredBundle : Bundle(path: buildPath) else {
            fatalError("could not load resource bundle: from \(mainPath) or \(buildPath)")
        }

        return bundle
    }()
}
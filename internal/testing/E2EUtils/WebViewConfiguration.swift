// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import UIKit

public extension NSObject {
    // swiftlint:disable:next identifier_name
    @objc func _openURLWithAuthenticationSession(url: URL) {
        let environment = ProcessInfo.processInfo.environment
        let userAgent = environment["JEST_CUSTOM_USER_AGENT"]
        let vc = WKWebViewController(url: url, callbackScheme: "fb421415891237674", userAgent: userAgent)
        vc.modalPresentationStyle = .fullScreen
        if var topController = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            topController.present(vc, animated: false, completion: nil)
        }
    }
}

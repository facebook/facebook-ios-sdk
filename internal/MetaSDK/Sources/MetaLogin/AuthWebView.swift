/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import AuthenticationServices
import Foundation

typealias AuthWebViewCompletion = (Result<URL, Error>) -> Void

@available(iOS 13.0, *)
struct AuthWebView {
    var configuredDependencies: InstanceDependencies?
    var defaultDependencies: InstanceDependencies? {
        .init(
            webAuthenticationSessionFactory: WebAuthenticationSessionFactory(),
            presentationContextProvider: WebAuthenticationSessionPresentationContextProvider()
        )
    }

    func openURL(
        url: URL,
        callbackURLScheme: String,
        completion: @escaping AuthWebViewCompletion
    ) {
        guard let dependencies = try? getDependencies() else { return }

        var session = dependencies.webAuthenticationSessionFactory.createWebAuthenticationSession(
            url: url,
            callbackURLScheme: callbackURLScheme,
            completionHandler: completion
        )

        session.presentationContextProvider = dependencies.presentationContextProvider

        session.start()
    }
}

@available(iOS 13.0, *)
extension AuthWebView: DependentAsInstance {
    struct InstanceDependencies {
        var webAuthenticationSessionFactory: WebAuthenticationSessionCreating
        var presentationContextProvider: ASWebAuthenticationPresentationContextProviding
    }
}

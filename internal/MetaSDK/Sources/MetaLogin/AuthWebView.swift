// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import AuthenticationServices
import Foundation

typealias AuthWebViewCompletion = (Result<URL, Error>) -> Void

struct AuthWebView {
    var configuredDependencies: InstanceDependencies?
    var defaultDependencies: InstanceDependencies? {
        .init(
            webAuthenticationSessionFactory: WebAuthenticationSessionFactory())
    }
    var presentationContextProvider = WebAuthenticationSessionPresentationContextProvider()

    func createWebAuthSession(
        url: URL,
        callbackURLScheme: String,
        completion: @escaping AuthWebViewCompletion
    ) {
        guard var dependencies = try? getDependencies() else { return }

        dependencies.webAuthenticationSessionFactory.createWebAuthenticationSession(
            url: url,
            callbackURLScheme: callbackURLScheme,
            completionHandler: completion
        )
    }
}

extension AuthWebView: DependentAsInstance {
    struct InstanceDependencies {
        var webAuthenticationSessionFactory: WebAuthenticationSessionCreating
    }
}

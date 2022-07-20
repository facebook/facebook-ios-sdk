// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

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
    ) -> Void {
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

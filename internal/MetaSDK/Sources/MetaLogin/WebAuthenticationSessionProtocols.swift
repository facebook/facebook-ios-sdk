// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation
import AuthenticationServices

protocol WebAuthenticationSessionCreating {
    func createWebAuthenticationSession(url: URL, callbackURLScheme: String?, completionHandler: @escaping AuthWebViewCompletion) -> WebAuthenticationSession
}

protocol WebAuthenticationSession {
    @available(iOS 13.0, *)
    var presentationContextProvider: ASWebAuthenticationPresentationContextProviding? {get set}
    
    @discardableResult
    mutating func start() -> Bool
}

extension ASWebAuthenticationSession: WebAuthenticationSession {}

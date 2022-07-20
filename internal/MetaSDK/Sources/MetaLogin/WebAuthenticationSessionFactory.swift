// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation
import AuthenticationServices

struct UnknownAuthenticationSessionError: Error {}

struct WebAuthenticationSessionFactory: WebAuthenticationSessionCreating {
    func createWebAuthenticationSession(
        url: URL,
        callbackURLScheme: String?,
        completionHandler: @escaping AuthWebViewCompletion
    ) -> WebAuthenticationSession {
        let handler: (URL?, Error?) -> Void = { potentialURL, potentialError in
            if let error = potentialError {
                completionHandler(.failure(error))
            }
            if let url = potentialURL {
                completionHandler(.success(url))
            }
            completionHandler(.failure(UnknownAuthenticationSessionError()))
        }
        return ASWebAuthenticationSession(url: url, callbackURLScheme: callbackURLScheme, completionHandler: handler)
    }
}

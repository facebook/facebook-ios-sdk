
// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation

@available(iOS 13.0, *)
class TestWebAuthenticationSessionFactory: WebAuthenticationSessionCreating {
    let stubbedSession: TestWebAuthenticationSession
    
    init(stubbedSession: TestWebAuthenticationSession) {
        self.stubbedSession = stubbedSession
    }

    var capturedURL: URL?
    var capturedCallbackURLScheme: String?
    var capturedCompletionHandler: AuthWebViewCompletion?
    
    func createWebAuthenticationSession(
        url: URL,
        callbackURLScheme: String?,
        completionHandler: @escaping AuthWebViewCompletion
    ) -> WebAuthenticationSession {
        capturedURL = url
        capturedCallbackURLScheme = callbackURLScheme
        capturedCompletionHandler = completionHandler
        return stubbedSession
    }
}

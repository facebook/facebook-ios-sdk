// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation

class TestWebAuthenticationSessionFactory: WebAuthenticationSessionCreating {
    let stubbedSession: TestWebAuthenticationSession

    init(stubbedSession: TestWebAuthenticationSession) {
        self.stubbedSession = stubbedSession
    }

    var capturedURL: URL?
    var capturedCallbackURLScheme: String?
    var capturedCompletionHandler: ASWebAuthenticationSession.CompletionHandler?
    func makeWebAuthenticationSession(
        url URL: URL,
        callbackURLScheme: String?,
        completionHandler: @escaping ASWebAuthenticationSession.CompletionHandler
    ) -> WebAuthenticationSession {
        capturedURL = URL
        capturedCallbackURLScheme = callbackURLScheme
        capturedCompletionHandler = completionHandler

        return stubbedSession
    }
}

/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
@testable import MetaLogin

final class TestWebAuthenticationSessionFactory: WebAuthenticationSessionCreating {
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

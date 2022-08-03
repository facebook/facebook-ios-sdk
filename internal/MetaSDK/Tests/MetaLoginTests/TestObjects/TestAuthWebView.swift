/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
@testable import MetaLogin

final class TestAuthWebView: AuthenticationSessionWebView {
    var openURLWasCalled = false
    var capturedURL: URL?
    var capturedCallbackURLScheme: String?
    var capturedCompletion: AuthWebViewCompletion?

    func openURL(
        url: URL,
        callbackURLScheme: String,
        completion: @escaping AuthWebViewCompletion
    ) {
        openURLWasCalled = true
        capturedURL = url
        capturedCallbackURLScheme = callbackURLScheme
        capturedCompletion = completion
    }
}

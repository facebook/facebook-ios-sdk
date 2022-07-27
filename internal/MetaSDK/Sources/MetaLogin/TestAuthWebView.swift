/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@available(iOS 13.0, *)
final class TestAuthWebView: AuthenticationSessionWebView {
    var openURLWasCalled = false

    func openURL(
        url: URL,
        callbackURLScheme: String,
        completion: @escaping AuthWebViewCompletion
    ) {
        openURLWasCalled = true
    }
}

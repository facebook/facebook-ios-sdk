/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import AuthenticationServices
@testable import MetaLogin

final class TestWebAuthenticationSession: WebAuthenticationSession {
    var presentationContextProvider: ASWebAuthenticationPresentationContextProviding?

    init(stubbedPresentationContextProvider: TestWebAuthenticationSessionPresentationContextProvider) {
        self.presentationContextProvider = stubbedPresentationContextProvider
    }

    var startWasCalled = false

    func start() -> Bool {
        startWasCalled = true
        return true
    }
}

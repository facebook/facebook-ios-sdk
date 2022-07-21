/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import AuthenticationServices

protocol WebAuthenticationSessionCreating {
    func createWebAuthenticationSession(
        url: URL,
        callbackURLScheme: String?,
        completionHandler: @escaping AuthWebViewCompletion
    ) -> WebAuthenticationSession
}

protocol WebAuthenticationSession {
    @available(iOS 13.0, *)
    var presentationContextProvider: ASWebAuthenticationPresentationContextProviding? {get set}

    @discardableResult
    func start() -> Bool
}

protocol AuthenticationSessionStatePersisting {
    var authenticationSessionState: AuthenticationSessionState {get set}
}

extension ASWebAuthenticationSession: WebAuthenticationSession {}

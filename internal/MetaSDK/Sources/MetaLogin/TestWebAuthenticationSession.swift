// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation
import AuthenticationServices

@available(iOS 13.0, *)
class TestWebAuthenticationSession: WebAuthenticationSession {
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

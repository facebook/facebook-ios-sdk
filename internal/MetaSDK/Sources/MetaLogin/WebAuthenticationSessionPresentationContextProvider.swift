// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation
import AuthenticationServices

class WebAuthenticationSessionPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}

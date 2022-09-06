/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import AuthenticationServices

// swiftlint:disable:next type_name line_length
final class DefaultASWebAuthenticationSessionPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    var anchor: ASPresentationAnchor?
    DispatchQueue.main.sync {
      anchor = ASPresentationAnchor()
    }

    guard let anchor = anchor else {
      fatalError("Unable to get a presentation anchor for web authentication")
    }

    return anchor
  }
}

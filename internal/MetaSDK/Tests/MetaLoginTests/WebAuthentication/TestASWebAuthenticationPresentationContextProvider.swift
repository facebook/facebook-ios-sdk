/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import AuthenticationServices
import Foundation

// swiftlint:disable:next type_name line_length
final class TestASWebAuthenticationPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {

  var anchor: ASPresentationAnchor?

  @MainActor
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    let anchorToUse: ASPresentationAnchor
    if let anchor = anchor {
      anchorToUse = anchor
    } else {
      anchorToUse = ASPresentationAnchor()
      anchor = anchorToUse
    }

    return anchorToUse
  }
}

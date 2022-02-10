/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import FBSDKCoreKit
import Foundation

/// A model for an instant games switchAsync cross play request.
@objcMembers
@objc(FBSDKSwitchContextContent)
public final class SwitchContextContent: NSObject, ValidatableProtocol {

  /**
   The context token of the existing context for which this request is being made.
   @return The context token of the existing context
   */
  var contextTokenID: String

  @objc(initDialogContentWithContextID:)
  public init(contextID: String) {
    contextTokenID = contextID
  }

  public override func isEqual(_ object: Any?) -> Bool {
    let contentObject = (object as? SwitchContextContent)
    return contextTokenID == contentObject?.contextTokenID
  }

  // MARK: - SharingValidation

  public func validate() throws {
    guard
      !contextTokenID.isEmpty
    else {
      let message = "The contextToken is required."
      let errorFactory = ErrorFactory()
      throw errorFactory.requiredArgumentError(
        name: "contextToken",
        message: message,
        underlyingError: nil
      )
    }
  }
}

#endif

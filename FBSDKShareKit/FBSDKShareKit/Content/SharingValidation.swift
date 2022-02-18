/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/// A base interface for validation of content and media.
@objc(FBSDKSharingValidation)
public protocol SharingValidation {
  /**
   Asks the receiver to validate that its content or media values are valid.
   - Parameter options:  The share bridge options to use for validation.
   - Throws: If the values are not valid.
   */
  @objc(validateWithOptions:error:)
  func validate(options: ShareBridgeOptions) throws
}

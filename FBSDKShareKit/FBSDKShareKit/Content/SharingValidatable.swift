/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/// An interface for validatable content and media.
@objc(FBSDKSharingValidatable)
public protocol SharingValidatable {
  /**
   Validate that this content or media contains valid values.
   - Parameter options:  The share bridge options to use for validation.
   - Throws: If the values are not valid.
   */
  @objc(validateWithOptions:error:)
  func validate(options: ShareBridgeOptions) throws
}

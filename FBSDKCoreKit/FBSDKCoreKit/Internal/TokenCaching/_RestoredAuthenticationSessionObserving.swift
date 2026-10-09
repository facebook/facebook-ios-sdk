/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 Implemented by a type in another kit that wants to know when the SDK restores a cached
 authentication token at launch. CoreKit cannot import the other kits, so the implementing
 type is looked up by its Objective-C name at runtime.

 @warning INTERNAL - DO NOT USE
 */
@objc(FBSDKRestoredAuthenticationSessionObserving)
public protocol _RestoredAuthenticationSessionObserving {
  /// Called on launch, after the SDK has restored a cached authentication token.
  static func didRestoreAuthenticationSession()
}

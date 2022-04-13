/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

// The login tracking preference to use for a login attempt. For more information on the differences between
/// `enabled` and `limited` see: https://developers.facebook.com/docs/facebook-login/ios/limited-login/
@objc(FBSDKLoginTracking)
public enum LoginTracking: UInt {
  case enabled
  case limited
}

#endif

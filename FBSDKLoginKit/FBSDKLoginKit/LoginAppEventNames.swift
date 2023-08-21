/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

extension AppEvents.Name {
  static let loginButtonDidTap = AppEvents.Name("fb_login_button_did_tap")

  // MARK: - Device Requests

  static let smartLoginService = AppEvents.Name("fb_smart_login_service")

  // MARK: - Login Manager

  /// Use to log the start of an auth request that cannot be fulfilled by the token cache
  static let sessionAuthStart = AppEvents.Name("fb_mobile_login_start")

  /// Use to log the end of an auth request that was not fulfilled by the token cache
  static let sessionAuthEnd = AppEvents.Name("fb_mobile_login_complete")

  /// Use to log the start of a specific auth method as part of an auth request
  static let sessionAuthMethodStart = AppEvents.Name("fb_mobile_login_method_start")

  /// Use to log the end of the last tried auth method as part of an auth request
  static let sessionAuthMethodEnd = AppEvents.Name("fb_mobile_login_method_complete")

  /// Use to log the post-login heartbeat event after  the end of an auth request
  static let sessionAuthHeartbeat = AppEvents.Name("fb_mobile_login_heartbeat")
}

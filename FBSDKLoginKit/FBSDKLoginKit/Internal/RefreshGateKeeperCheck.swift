/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

/// Checks if silent refresh is enabled via GateKeeper.
/// Server-side GK: platform_login_oidc_prompt_none_fb
/// Client-side feature key: FBSDKFeatureLimitedLoginRefresh
final class RefreshGateKeeperCheck {
  static func isSilentRefreshEnabled() -> Bool {
    _FeatureManager.shared.isEnabled(.limitedLoginRefresh)
  }
}

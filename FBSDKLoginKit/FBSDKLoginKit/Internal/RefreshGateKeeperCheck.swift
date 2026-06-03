/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

/// SDK-side kill switch for the Limited Login Refresh feature.
///
/// The SDK queries the feature key `FBSDKFeatureLimitedLoginRefresh` via
/// `_FeatureManager`. That key is mapped server-side (in the `MOBILE_SDK_GK_KEYS`
/// sitevar; see D95281666 and D95339723) to the **app-keyed** GK
/// `mobile_sdk_limited_login_refresh_enabled`, which is the rollout dial
/// operators flip per app_id. SDK GK lookups don't carry a user_id, so this
/// gate has to be app-keyed.
///
/// Note: a historical user-keyed privacy GK
/// (`platform_login_oidc_prompt_none_fb`) once gated the server-side OAuth dialog
/// and refresh endpoints, but it was unified away in D104182324 — www now
/// evaluates the same app-keyed `mobile_sdk_limited_login_refresh_enabled`
/// (per app_id), so the SDK and server gate on one dial and roll out together.
/// No separate privacy GK needs to be open.
///
/// Despite the historical method name (`isSilentRefreshEnabled`), this gate
/// covers the entire Limited Login Refresh feature: the silent path, the direct
/// path, and `dpop_jkt` emission at initial Limited Login. Renaming is deferred
/// to avoid touching every call site landed in Phase 1-2.
final class RefreshGateKeeperCheck {
  static func isSilentRefreshEnabled() -> Bool {
    _FeatureManager.shared.isEnabled(.limitedLoginRefresh)
  }
}

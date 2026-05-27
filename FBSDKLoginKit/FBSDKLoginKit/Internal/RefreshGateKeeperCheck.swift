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
/// Note: there is also a **user-keyed** privacy GK
/// (`platform_login_oidc_prompt_none_fb`) enforced server-side on the OAuth
/// dialog and refresh endpoints. That one is *not* consulted from the SDK and
/// is independent of this check; both must be open for the feature to work
/// end-to-end.
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

/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import TestTools

/// Hands `TestSettings` to the Objective-C tests. They cannot construct it directly because it
/// lives in the Swift-only `TestTools` module, which does not surface in their bridging header.
@objcMembers
final class TestSettingsFactory: NSObject {

  /// A settings double that permits user journey metadata collection.
  ///
  /// Required rather than convenient: `FBSDKMetaDataCollectionEnabled` defaults to off, so a test
  /// left on the real shared settings has every cache write silently suppressed and its
  /// assertions pass vacuously.
  static func settingsWithMetaDataCollectionEnabled() -> SettingsProtocol {
    let settings = TestSettings()
    settings.isMetaDataCollectionEnabled = true
    return settings
  }
}

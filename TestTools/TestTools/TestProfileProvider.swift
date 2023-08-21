/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

@objcMembers
public final class TestProfileProvider: NSObject, ProfileProviding {

  public static var current: Profile?
  public static var stubbedCachedProfile: Profile?

  public static func fetchCachedProfile() -> Profile? {
    stubbedCachedProfile
  }

  public static func reset() {
    current = nil
    stubbedCachedProfile = nil
  }
}

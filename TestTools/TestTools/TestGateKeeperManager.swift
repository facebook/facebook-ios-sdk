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
public final class TestGateKeeperManager: NSObject, _GateKeeperManaging {
  public static var gateKeepers = [String?: Bool]()
  public static var loadGateKeepersWasCalled = false
  public static var capturedLoadGateKeepersCompletion: _GKManagerBlock?
  public static var capturedBoolForGateKeeperKeys = [String]()

  public static func setGateKeeperValue(key: String, value: Bool) {
    gateKeepers[key] = value
  }

  public static func bool(forKey key: String, defaultValue: Bool) -> Bool {
    capturedBoolForGateKeeperKeys.append(key)
    if let value = gateKeepers[key] {
      return value
    } else {
      return defaultValue
    }
  }

  public static func loadGateKeepers(_ completionBlock: @escaping _GKManagerBlock) {
    loadGateKeepersWasCalled = true
    capturedLoadGateKeepersCompletion = completionBlock
  }

  public static func reset() {
    gateKeepers = [:]
    loadGateKeepersWasCalled = false
    capturedLoadGateKeepersCompletion = nil
    capturedBoolForGateKeeperKeys = []
  }
}

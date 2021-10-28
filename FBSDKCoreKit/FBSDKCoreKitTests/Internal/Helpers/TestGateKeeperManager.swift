/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@objcMembers
class TestGateKeeperManager: NSObject, GateKeeperManaging {
  static var gateKeepers = [String?: Bool]()
  static var loadGateKeepersWasCalled = false
  static var capturedLoadGateKeepersCompletion: GKManagerBlock?
  static var capturedBoolForGateKeeperKeys = [String]()

  static func setGateKeeperValue(key: String, value: Bool) {
    gateKeepers[key] = value
  }

  static func bool(forKey key: String, defaultValue: Bool) -> Bool {
    capturedBoolForGateKeeperKeys.append(key)
    if let value = gateKeepers[key] {
      return value
    } else {
      return defaultValue
    }
  }

  static func loadGateKeepers(_ completionBlock: @escaping GKManagerBlock) {
    loadGateKeepersWasCalled = true
    capturedLoadGateKeepersCompletion = completionBlock
  }

  static func reset() {
    gateKeepers = [:]
    loadGateKeepersWasCalled = false
    capturedLoadGateKeepersCompletion = nil
    capturedBoolForGateKeeperKeys = []
  }
}

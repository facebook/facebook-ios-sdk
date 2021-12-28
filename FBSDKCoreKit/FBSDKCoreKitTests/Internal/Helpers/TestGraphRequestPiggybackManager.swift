/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

@objcMembers
class TestGraphRequestPiggybackManager: NSObject, GraphRequestPiggybackManaging {

  static var capturedConnection: GraphRequestConnecting?
  static var addRefreshPiggybackWasCalled = false

  static func addPiggybackRequests(_ connection: GraphRequestConnecting) {
    capturedConnection = connection
  }

  static func addRefreshPiggyback(
    _ connection: GraphRequestConnecting,
    permissionHandler: GraphRequestCompletion? = nil
  ) {
    addRefreshPiggybackWasCalled = true
  }

  static func reset() {
    capturedConnection = nil
    addRefreshPiggybackWasCalled = false
  }
}

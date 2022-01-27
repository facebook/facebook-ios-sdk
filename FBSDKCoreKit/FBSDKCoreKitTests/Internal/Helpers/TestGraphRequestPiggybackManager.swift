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
final class TestGraphRequestPiggybackManager: NSObject, GraphRequestPiggybackManaging {

  var capturedConnection: GraphRequestConnecting?
  var addRefreshPiggybackWasCalled = false

  func addPiggybackRequests(_ connection: GraphRequestConnecting) {
    capturedConnection = connection
  }

  func addRefreshPiggyback(
    _ connection: GraphRequestConnecting,
    permissionHandler: GraphRequestCompletion? = nil
  ) {
    addRefreshPiggybackWasCalled = true
  }
}

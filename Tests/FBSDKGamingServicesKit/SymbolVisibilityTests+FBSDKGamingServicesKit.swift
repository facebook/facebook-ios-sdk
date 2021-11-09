/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKGamingServicesKit
import XCTest

class SymbolVisibilityTests: XCTestCase {
  func testCanSeeReexportedSymbol() {
    _ = Mirror(reflecting: FriendFinderDialog.self)
    _ = Mirror(reflecting: FBSDKSwitchContextDialog.self)
  }
}

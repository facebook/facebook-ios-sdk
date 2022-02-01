/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKGamingServicesKit
import XCTest

class SymbolVisibilityTests_FBSDKGamingServicesKit: XCTestCase { // swiftlint:disable:this type_name
  func testCanSeeReexportedSymbol() {
    _ = Mirror(reflecting: FriendFinderDialog.self)
    _ = Mirror(reflecting: FBSDKSwitchContextDialog.self)
  }
}

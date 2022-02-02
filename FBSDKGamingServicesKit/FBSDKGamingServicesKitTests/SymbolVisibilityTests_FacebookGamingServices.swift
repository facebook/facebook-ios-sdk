/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FacebookGamingServices
import XCTest

final class SymbolVisibilityTests_FacebookGamingServices: XCTestCase { // swiftlint:disable:this type_name

  func testCanSeeReexportedSymbol() {
    _ = Mirror(reflecting: FriendFinderDialog.self)
  }
}

/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import TestTools
import XCTest

class InternalUtilityTests: XCTestCase {

  override func setUp() {
    super.setUp()

    InternalUtility.reset()
  }

  func testDefaultInfoDictionaryProvider() {
    XCTAssertNil(
      InternalUtility.shared.infoDictionaryProvider,
      "Should not have an info dictionary provider by default"
    )
  }

  func testConfiguringWithInfoDictionaryProvider() {
    let bundle = TestBundle()
    InternalUtility.configure(withInfoDictionaryProvider: bundle)

    XCTAssertTrue(
      InternalUtility.shared.infoDictionaryProvider === bundle,
      "Should be able to provide an info dictionary provider"
    )
  }
}

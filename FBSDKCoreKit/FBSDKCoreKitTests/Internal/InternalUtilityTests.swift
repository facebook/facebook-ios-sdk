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

  func testDefaultDependencies() {
    XCTAssertNil(
      InternalUtility.shared.infoDictionaryProvider,
      "Should not have an info dictionary provider by default"
    )
    XCTAssertNil(
      InternalUtility.shared.loggerFactory,
      "Should not have a logger factory by default"
    )
  }

  func testConfiguringWithDependencies() {
    let bundle = TestBundle()
    let loggerFactory = TestLoggerFactory()
    InternalUtility.shared.configure(
      withInfoDictionaryProvider: bundle,
      loggerFactory: loggerFactory
    )

    XCTAssertTrue(
      InternalUtility.shared.infoDictionaryProvider === bundle,
      "Should be able to provide an info dictionary provider"
    )
    XCTAssertTrue(
      InternalUtility.shared.loggerFactory === loggerFactory,
      "The shared instance should use the provided logger factory"
    )
  }
}

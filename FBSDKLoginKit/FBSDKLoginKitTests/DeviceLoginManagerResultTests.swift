/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKLoginKit
import TestTools
import XCTest

final class DeviceLoginManagerResultTests: XCTestCase {

  func testCreateDeviceLoginManagerResultWithToken() {
    let accessToken = SampleAccessTokens.validToken
    let result = DeviceLoginManagerResult(token: accessToken, isCancelled: false)

    XCTAssertNotNil(result)
    XCTAssertEqual(result.accessToken, accessToken)
    XCTAssertFalse(result.isCancelled)
  }

  func testCreateDeviceLoginManagerResultWithNilToken() {
    let result = DeviceLoginManagerResult(token: nil, isCancelled: true)

    XCTAssertNotNil(result)
    XCTAssertNil(result.accessToken)
    XCTAssertTrue(result.isCancelled)
  }
}

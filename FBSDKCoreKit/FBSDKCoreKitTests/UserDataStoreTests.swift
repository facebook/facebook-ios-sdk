/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import XCTest

final class UserDataStoreTests: XCTestCase {

  let store = UserDataStore()
  let email = "apptest@fb.com"

  override func setUp() {
    super.setUp()

    store.clearUserData()
  }

  override func tearDown() {
    super.tearDown()

    store.clearUserData()
  }

  func testSettingUserDataByType() throws {
    let hashedEmail = try XCTUnwrap(
      BasicUtility.sha256Hash(NSString(utf8String: email))
    )

    store.setUserData(email, forType: .email)
    let retrieved = try XCTUnwrap(
      store.getUserData(),
      "Should be able to retrieve stored user data"
    )

    XCTAssertTrue(
      retrieved.contains("em"),
      "Should store the data under the expected key"
    )
    XCTAssertTrue(
      retrieved.contains(hashedEmail),
      "Should hash the data before storing it"
    )
  }

  func testClearingUserDataByType() throws {
    store.setUserData(email, forType: .email)
    store.setUserData(name, forType: .firstName)
    store.clearUserData(forType: .email)

    let retrieved = try XCTUnwrap(
      store.getUserData(),
      "Should be able to retrieve stored user data"
    )

    // User data is stored as a string representation of a dictionary.
    // example: `{"key": "hashed value"}`
    XCTAssertFalse(
      retrieved.contains("em"),
      "Should clear the provided type of user data"
    )
    XCTAssertTrue(
      retrieved.contains("fn"),
      "Should not clear unspecified user data"
    )
  }
}

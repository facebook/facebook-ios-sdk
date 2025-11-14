/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import XCTest

final class UserDataStoreTests: XCTestCase {

  let store = _UserDataStore()
  let email = "apptest@fb.com"
  let firstName = "Test User"

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
    store.setUserData(firstName, forType: .firstName)
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

  func testSettingUserDataWithoutExternalIdPreservesExistingExternalId() throws {
    let externalId = "test_external_id_123"

    // First, set the external ID explicitly
    store.setUserData(externalId, forType: .externalId)

    let initialData = try XCTUnwrap(
      store.getUserData(),
      "Should be able to retrieve initial user data"
    )

    XCTAssertTrue(
      initialData.contains("external_id"),
      "Should contain external_id after setting it"
    )

    // Now set other user data fields without passing external ID
    store.setUser(
      email: email,
      firstName: "Test",
      lastName: "User",
      phone: "1234567890",
      dateOfBirth: "01/01/1990",
      gender: "m",
      city: "Seattle",
      state: "WA",
      zip: "98101",
      country: "US"
    )

    let finalData = try XCTUnwrap(
      store.getUserData(),
      "Should be able to retrieve final user data"
    )

    // Verify external ID is still present
    XCTAssertTrue(
      finalData.contains("external_id"),
      "Should preserve external_id when setting other user data fields"
    )

    // Verify other fields were set
    XCTAssertTrue(
      finalData.contains("em"),
      "Should contain email after setting user data"
    )
    XCTAssertTrue(
      finalData.contains("fn"),
      "Should contain first name after setting user data"
    )
  }
}

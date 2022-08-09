/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import MetaLogin
import XCTest

final class KeychainStorageTests: XCTestCase {
  var bundle: TestBundle!
  var keychainStorage: KeychainStorage!

  override func setUp() {
    super.setUp()

    bundle = TestBundle()
    keychainStorage = KeychainStorage(bundle: bundle)
  }

  override func tearDown() {
    bundle = nil
    keychainStorage = nil

    super.tearDown()
  }

  func testKeychainAccount() throws {
    bundle.stubbedBundleIdentifier = "test"
    XCTAssertEqual(
      bundle.stubbedBundleIdentifier,
      keychainStorage.keychainAccount,
      "The keychain account should be set the the bundle identifier"
    )

    bundle.stubbedBundleIdentifier = nil
    XCTAssertEqual(
      "unknown",
      keychainStorage.keychainAccount,
      "The keychain account should have a default value of 'unknown' when the bundle identifier is nil"
    )
  }
}

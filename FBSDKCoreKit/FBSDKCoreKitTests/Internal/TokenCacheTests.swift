/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import XCTest

final class TokenCacheTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var cache: TokenCache!
  var settings: TestSettings!
  var keychainStore: TestKeychainStore!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    settings = TestSettings()
    keychainStore = TestKeychainStore()
    cache = TokenCache(settings: settings, keychainStore: keychainStore)
  }

  func testSettings() {
    XCTAssertTrue(
      cache.settings === settings,
      "The cache should be created with the provided settings"
    )
  }

  func testKeychainStore() throws {
    XCTAssertTrue(
      cache.keychainStore === keychainStore,
      "The cache should be created with the provided keychain store"
    )
  }
}

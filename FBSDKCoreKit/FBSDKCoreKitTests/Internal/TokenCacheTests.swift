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
  var store: TestDataStore!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    settings = TestSettings()
    keychainStore = TestKeychainStore()
    store = TestDataStore()
    cache = TokenCache()
    cache.setDependencies(
      .init(
        settings: settings,
        keychainStore: keychainStore,
        dataStore: store
      )
    )
  }

  override func tearDown() {
    settings = nil
    keychainStore = nil
    store = nil
    cache = nil

    super.tearDown()
  }

  func testDefaultTypeDependencies() {
    XCTAssertNil(
      try? TokenCache().getDependencies(),
      "TokenCache does not have dependencies by default"
    )
  }

  func testSettingsDependencies() {
    XCTAssertTrue(
      cache.settings === settings,
      "Can set a settings for the cache"
    )
    XCTAssertTrue(
      cache.keychainStore === keychainStore,
      "Can set a keychain store for the cache"
    )
    XCTAssertTrue(
      cache.dataStore === store,
      "Can set a store for the cache"
    )
  }
}

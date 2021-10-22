/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

extension FBSDKAppEventsUtilityTests {

  func testIsSensitiveUserData() {
    var text = "test@sample.com"
    XCTAssertTrue(AppEventsUtility.isSensitiveUserData(text))

    text = "4716 5255 0221 9085"
    XCTAssertTrue(AppEventsUtility.isSensitiveUserData(text))

    text = "4716525502219085"
    XCTAssertTrue(AppEventsUtility.isSensitiveUserData(text))

    text = "4716525502219086"
    XCTAssertFalse(AppEventsUtility.isSensitiveUserData(text))

    text = ""
    XCTAssertFalse(AppEventsUtility.isSensitiveUserData(text))

    // number of digits less than 9 will not be considered as credit card number
    text = "4716525"
    XCTAssertFalse(AppEventsUtility.isSensitiveUserData(text))
  }

  func testIdentifierManagerWithShouldUseCachedManagerWithCachedManager() {
    let cachedManager = ASIdentifierManager()
    AppEventsUtility.cachedAdvertiserIdentifierManager = cachedManager
    let resolver = TestDylibResolver()

    let manager = AppEventsUtility.shared.asIdentifierManager(
      shouldUseCachedManager: true,
      dynamicFrameworkResolver: resolver
    )

    XCTAssertEqual(
      manager,
      cachedManager,
      "Should use the cached manager when available and indicated"
    )
    XCTAssertFalse(
      resolver.didLoadIdentifierManagerClass,
      "Should not dynamically load the identifier manager class"
    )
  }

  func testIdentifierManagerWithShouldUseCachedManagerWithoutCachedManager() {
    let resolver = TestDylibResolver()
    resolver.stubbedASIdentifierManagerClass = ASIdentifierManager.self

    guard AppEventsUtility.cachedAdvertiserIdentifierManager == nil else {
      return XCTFail("Should not begin the test with a cached manager")
    }

    let manager = AppEventsUtility.shared.asIdentifierManager(
      shouldUseCachedManager: true,
      dynamicFrameworkResolver: resolver
    )

    XCTAssertTrue(
      resolver.didLoadIdentifierManagerClass,
      "Should dynamically load the identifier manager class"
    )
    XCTAssertNotNil(
      manager,
      "Should retrieve a manager instance when no cache is available"
    )
    XCTAssertEqual(
      manager,
      AppEventsUtility.cachedAdvertiserIdentifierManager,
      "Should cache the retrieved manager instance"
    )
  }

  func testIdentifierManagerWithShouldNotUseCachedManagerWithCachedManager() {
    let cachedManager = ASIdentifierManager()
    AppEventsUtility.cachedAdvertiserIdentifierManager = cachedManager
    let resolver = TestDylibResolver()
    resolver.stubbedASIdentifierManagerClass = ASIdentifierManager.self

    let manager = AppEventsUtility.shared.asIdentifierManager(
      shouldUseCachedManager: false,
      dynamicFrameworkResolver: resolver
    )

    XCTAssertTrue(
      resolver.didLoadIdentifierManagerClass,
      "Should dynamically load the identifier manager class"
    )
    XCTAssertNotNil(
      manager,
      "Should retrieve a manager instance when a cache is available but caching is declined"
    )
    XCTAssertNil(
      AppEventsUtility.cachedAdvertiserIdentifierManager,
      "Should clear the cache when caching is declined"
    )
  }

  func testIdentifierManagerWithShouldNotUseCachedManagerWithoutCachedManager() {
    let resolver = TestDylibResolver()
    resolver.stubbedASIdentifierManagerClass = ASIdentifierManager.self

    guard AppEventsUtility.cachedAdvertiserIdentifierManager == nil else {
      return XCTFail("Should not begin the test with a cached manager")
    }

    let manager = AppEventsUtility.shared.asIdentifierManager(
      shouldUseCachedManager: false,
      dynamicFrameworkResolver: resolver
    )

    XCTAssertTrue(
      resolver.didLoadIdentifierManagerClass,
      "Should dynamically load the identifier manager class"
    )
    XCTAssertNotNil(
      manager,
      "Should retrieve a manager instance when caching is declined"
    )
    XCTAssertNil(
      AppEventsUtility.cachedAdvertiserIdentifierManager,
      "Should clear the cache when caching is declined"
    )
  }
}

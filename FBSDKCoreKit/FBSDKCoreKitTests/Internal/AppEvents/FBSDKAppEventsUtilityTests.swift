// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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

    let manager = AppEventsUtility.asIdentifierManager(
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

    let manager = AppEventsUtility.asIdentifierManager(
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

    let manager = AppEventsUtility.asIdentifierManager(
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

    let manager = AppEventsUtility.asIdentifierManager(
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

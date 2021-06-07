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

import XCTest

class BackgroundEventLoggerTests: XCTestCase {

  let bundleWithIdentifier = TestBundle(infoDictionary: ["BGTaskSchedulerPermittedIdentifiers": ["123"]])
  let bundleWithoutIdentifier = TestBundle()
  let logger = TestEventLogger()
  var backgroundEventLogger: BackgroundEventLogger! // swiftlint:disable:this implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    backgroundEventLogger = BackgroundEventLogger(
        infoDictionaryProvider: bundleWithIdentifier,
        eventLogger: logger
    )
  }

  func testCreating() {
    XCTAssertTrue(
      backgroundEventLogger.infoDictionaryProvider is TestBundle,
      "Should use the provided info dictionary provider type"
    )
    XCTAssertTrue(
      backgroundEventLogger.eventLogger is TestEventLogger,
      "Should use the provided event logger type"
    )
  }

  func testLogBackgroundStatusWithBackgroundRefreshStatusAvailable() {
    backgroundEventLogger.logBackgroundRefresStatus(.available)

    XCTAssertEqual(
      logger.capturedEventName,
      "fb_sdk_background_status_available",
      "AppEvents instance should log fb_sdk_background_status_available if background refresh status is available"
    )
  }

  func testLogBackgroundStatusWithBackgroundRefreshStatusDenied() {
    backgroundEventLogger.logBackgroundRefresStatus(.denied)

    XCTAssertEqual(
      logger.capturedEventName,
      "fb_sdk_background_status_denied",
      "AppEvents instance should log fb_sdk_background_status_denied if background refresh status is available"
    )
  }

  func testLogBackgroundStatusWithBackgroundRefreshStatusRestricted() {
    backgroundEventLogger.logBackgroundRefresStatus(.restricted)

    XCTAssertEqual(
      logger.capturedEventName,
      "fb_sdk_background_status_restricted",
      "AppEvents instance should log fb_sdk_background_status_restricted if background refresh status is available"
    )
  }

  func testIsNewBackgroundRefreshWithIdentifiers() {
    XCTAssertTrue(
      backgroundEventLogger._isNewBackgroundRefresh(),
      "Should expect background refresh API is the new one if the identifier exists"
    )
  }

  func testIsNewBackgroundRefreshWithoutIdentifiers() {
    backgroundEventLogger = BackgroundEventLogger(
        infoDictionaryProvider: bundleWithoutIdentifier,
        eventLogger: logger
    )

    XCTAssertFalse(
      backgroundEventLogger._isNewBackgroundRefresh(),
      "Should expect background refresh API is the new one if the identifier exists"
    )
  }
}

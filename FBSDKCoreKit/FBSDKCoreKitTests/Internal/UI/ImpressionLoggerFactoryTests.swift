/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import TestTools
import XCTest

final class ImpressionLoggerFactoryTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var factory: ImpressionLoggerFactory!
  var graphRequestFactory: TestGraphRequestFactory!
  var eventLogger: TestEventLogger!
  var notificationCenter: TestNotificationCenter!
  var accessTokenWallet: TestAccessTokenWallet.Type!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    graphRequestFactory = TestGraphRequestFactory()
    eventLogger = TestEventLogger()
    notificationCenter = TestNotificationCenter()
    accessTokenWallet = TestAccessTokenWallet.self

    factory = ImpressionLoggerFactory(
      graphRequestFactory: graphRequestFactory,
      eventLogger: eventLogger,
      notificationCenter: notificationCenter,
      accessTokenWallet: accessTokenWallet
    )
  }

  override func tearDown() {
    factory = nil
    graphRequestFactory = nil
    eventLogger = nil
    notificationCenter = nil
    accessTokenWallet = nil

    super.tearDown()
  }

  func testInitialization() {
    XCTAssertTrue(
      factory.graphRequestFactory === graphRequestFactory,
      "Should use the provided graph request factory"
    )
    XCTAssertTrue(
      factory.eventLogger === eventLogger,
      "Should use the provided event logger"
    )
    XCTAssertTrue(
      factory.notificationCenter === notificationCenter,
      "Should use the provided notification center"
    )
    XCTAssertTrue(
      factory.accessTokenWallet === accessTokenWallet,
      "Should use the provided access token wallet"
    )
  }

  func testCreatingImpressionLogger() {
    let logger = factory.makeImpressionLogger(withEventName: .adClick)

    XCTAssertTrue(
      logger is _ViewImpressionLogger,
      "Should make the correct type of impression logger"
    )
  }
}

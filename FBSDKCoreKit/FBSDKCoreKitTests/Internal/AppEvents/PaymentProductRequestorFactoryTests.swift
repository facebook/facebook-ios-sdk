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

final class PaymentProductRequestorFactoryTests: XCTestCase {

  let settings = TestSettings()
  let eventLogger = TestEventLogger()
  let store = UserDefaultsSpy()
  let loggerFactory = TestLoggerFactory()
  let graphRequestFactory = TestProductsRequestFactory()
  let receiptProvider = TestAppStoreReceiptProvider()
  lazy var factory = PaymentProductRequestorFactory(
    settings: settings,
    eventLogger: eventLogger,
    gateKeeperManager: TestGateKeeperManager.self,
    store: store,
    loggerFactory: loggerFactory,
    productsRequestFactory: graphRequestFactory,
    receiptProvider: receiptProvider
  )

  override func setUp() {
    super.setUp()

    TestGateKeeperManager.reset()
  }

  override class func tearDown() {
    super.tearDown()

    TestGateKeeperManager.reset()
  }

  // MARK: - Dependencies

  func testCreatingWithCustomDependencies() {
    XCTAssertEqual(
      factory.settings as? TestSettings,
      settings,
      "Should use the provided settings"
    )
    XCTAssertEqual(
      factory.eventLogger as? TestEventLogger,
      eventLogger,
      "Should use the provided event logger"
    )
    XCTAssertTrue(
      factory.gateKeeperManager is TestGateKeeperManager.Type,
      "Should use the provided gate keeper manager"
    )
    XCTAssertEqual(
      factory.store as? UserDefaultsSpy,
      store,
      "Should use the provided persistent data store"
    )
    XCTAssertTrue(
      factory.loggerFactory is TestLoggerFactory,
      "Should use the provided logger factory"
    )
    XCTAssertTrue(
      factory.productsRequestFactory is TestProductsRequestFactory,
      "Should use the provided product request factory"
    )
    XCTAssertTrue(
      factory.appStoreReceiptProvider is TestAppStoreReceiptProvider,
      "Should use the provided app store receipt provider"
    )
  }

  func testCreatingRequestor() {
    let transaction = SKPaymentTransaction()
    let requestor = factory.createRequestor(transaction: transaction)

    XCTAssertEqual(
      requestor.transaction,
      transaction,
      "Should create a requestor using the expected transaction"
    )
    XCTAssertEqual(
      requestor.settings as? TestSettings,
      settings,
      "Should create a requestor using the expected settings"
    )
    XCTAssertEqual(
      requestor.eventLogger as? TestEventLogger,
      eventLogger,
      "Should create a requestor using the expected event logger"
    )
    XCTAssertTrue(
      requestor.gateKeeperManager is TestGateKeeperManager.Type,
      "Should create a requestor using the expected gate keeper manager"
    )
    XCTAssertEqual(
      requestor.store as? UserDefaultsSpy,
      store,
      "Should create a requestor using the expected persistent data store"
    )
    XCTAssertTrue(
      requestor.loggerFactory is TestLoggerFactory,
      "Should create a requestor using the expected logger"
    )
    XCTAssertTrue(
      requestor.productRequestFactory is TestProductsRequestFactory,
      "Should create a requestor using the expected product request factory"
    )
    XCTAssertTrue(
      requestor.appStoreReceiptProvider is TestAppStoreReceiptProvider,
      "Should create a requestor using the expected app store receipt provider"
    )
  }
}

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

  // swiftlint:disable implicitly_unwrapped_optional
  var settings: TestSettings!
  var eventLogger: TestEventLogger!
  var store: UserDefaultsSpy!
  var loggerFactory: TestLoggerFactory!
  var graphRequestFactory: TestProductsRequestFactory!
  var receiptProvider: TestAppStoreReceiptProvider!
  var factory: _PaymentProductRequestorFactory!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    TestGateKeeperManager.reset()

    settings = TestSettings()
    eventLogger = TestEventLogger()
    store = UserDefaultsSpy()
    loggerFactory = TestLoggerFactory()
    graphRequestFactory = TestProductsRequestFactory()
    receiptProvider = TestAppStoreReceiptProvider()
    factory = _PaymentProductRequestorFactory()

    _PaymentProductRequestorFactory.setDependencies(
      .init(
        settings: settings,
        eventLogger: eventLogger,
        gateKeeperManager: TestGateKeeperManager.self,
        store: store,
        loggerFactory: loggerFactory,
        productsRequestFactory: graphRequestFactory,
        appStoreReceiptProvider: receiptProvider
      )
    )
  }

  override func tearDown() {
    super.tearDown()

    TestGateKeeperManager.reset()
    settings = nil
    eventLogger = nil
    store = nil
    loggerFactory = nil
    graphRequestFactory = nil
    receiptProvider = nil
    _PaymentProductRequestorFactory.resetDependencies()
    factory = nil
  }

  // MARK: - Dependencies

  func testDefaultTypeDependencies() throws {
    _PaymentProductRequestorFactory.resetDependencies()
    let dependencies = try _PaymentProductRequestorFactory.getDependencies()

    XCTAssertIdentical(
      dependencies.settings as AnyObject,
      Settings.shared,
      .defaultDependency("the shared settings", for: "settings sharing")
    )

    XCTAssertIdentical(
      dependencies.eventLogger as AnyObject,
      AppEvents.shared,
      .defaultDependency("the shared app events", for: "event logging")
    )

    XCTAssertIdentical(
      dependencies.gateKeeperManager,
      _GateKeeperManager.self,
      .defaultDependency("the gatekeeper manager type", for: "gatekeeping")
    )

    XCTAssertIdentical(
      dependencies.store as AnyObject,
      UserDefaults.standard,
      .defaultDependency("the standard user defaults", for: "data persisting")
    )

    XCTAssertTrue(
      dependencies.loggerFactory is _LoggerFactory,
      .defaultDependency("a logger factory", for: "logger creating")
    )

    XCTAssertTrue(
      dependencies.productsRequestFactory is _ProductRequestFactory,
      .defaultDependency("a products request factory", for: "product request creating")
    )

    XCTAssertIdentical(
      dependencies.appStoreReceiptProvider as AnyObject,
      Bundle(for: ApplicationDelegate.self),
      .defaultDependency("the framework's bundle", for: "app store receipt providing")
    )
  }

  func testCustomTypeDependencies() throws {
    let dependencies = try _PaymentProductRequestorFactory.getDependencies()

    XCTAssertIdentical(
      dependencies.settings as AnyObject,
      settings,
      .customDependency(for: "settings sharing")
    )

    XCTAssertIdentical(
      dependencies.eventLogger as AnyObject,
      eventLogger,
      .customDependency(for: "event logging")
    )

    XCTAssertIdentical(
      dependencies.gateKeeperManager,
      TestGateKeeperManager.self,
      .customDependency(for: "gatekeeping")
    )

    XCTAssertIdentical(
      dependencies.store as AnyObject,
      store,
      .customDependency(for: "data persisting")
    )

    XCTAssertIdentical(
      dependencies.loggerFactory as AnyObject,
      loggerFactory,
      .customDependency(for: "logger creating")
    )

    XCTAssertIdentical(
      dependencies.productsRequestFactory as AnyObject,
      graphRequestFactory,
      .customDependency(for: "product request creating")
    )

    XCTAssertIdentical(
      dependencies.appStoreReceiptProvider as AnyObject,
      receiptProvider,
      .customDependency(for: "app store receipt providing")
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

// swiftformat:disable extensionaccesscontrol

// MARK: - Assumptions

fileprivate extension String {
  static func defaultDependency(_ dependency: String, for type: String) -> String {
    "The _PaymentProductRequestorFactory type uses \(dependency) as its \(type) dependency by default"
  }

  static func customDependency(for type: String) -> String {
    "The _PaymentProductRequestorFactory type uses a custom \(type) dependency when provided"
  }
}

/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit
@testable import IAPTestsHostApp

import StoreKit
import StoreKitTest
import TestTools
import XCTest

final class IAPDedupeProcessorTests: StoreKitTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var dedupeProcessor: IAPDedupeProcessor!
  var eventLogger: TestEventLogger!
  var prodDedupConfig: [String: [String]]!
  var testDedupConfig: [String: [String]]!
  var appEventsConfigurationProvider: TestAppEventsConfigurationProvider!
  var queue: SKPaymentQueue!
  var iapSKProductRequestFactory: TestIAPSKProductsRequestFactory!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() async throws {
    try await super.setUp()
    queue = SKPaymentQueue.default()
    eventLogger = TestEventLogger()
    appEventsConfigurationProvider = TestAppEventsConfigurationProvider()
    prodDedupConfig = [
      "fb_content_id": ["fb_content_id", "fb_product_item_id"],
      "fb_content_title": ["fb_content_title"],
      "fb_description": ["fb_description"],
      "_valueToSum": ["_valueToSum", "fb_product_price_amount"],
      "fb_currency": ["fb_currency", "fb_product_price_currency"],
    ]
    testDedupConfig = [
      "iap_test_key_1": ["iap_test_key_1", "iap_test_key_3"],
      "iap_test_key_2": ["iap_test_key_2"],
      "fb_transaction_id": ["fb_transaction_id"],
    ]
    let appEventsConfig = _AppEventsConfiguration(
      defaultATEStatus: AdvertisingTrackingStatus.unspecified,
      advertiserIDCollectionEnabled: true,
      eventCollectionEnabled: false,
      iapObservationTime: 3600000000000,
      iapManualAndAutoLogDedupWindow: 10000,
      iapProdDedupConfiguration: prodDedupConfig,
      iapTestDedupConfiguration: testDedupConfig
    )
    appEventsConfigurationProvider.stubbedConfiguration = appEventsConfig
    IAPTransactionObserver.shared.configuredDependencies = .init(
      iapTransactionLoggingFactory: IAPTransactionLoggingFactory(),
      paymentQueue: queue,
      appEventsConfigurationProvider: appEventsConfigurationProvider
    )
    IAPTransactionObserver.shared.startObserving()
    IAPDedupeProcessor.configuredDependencies = .init(
      eventLogger: eventLogger,
      appEventsConfigurationProvider: appEventsConfigurationProvider
    )
    IAPTransactionLogger.configuredDependencies = .init(
      eventLogger: eventLogger,
      appStoreReceiptProvider: Bundle.main
    )
    iapSKProductRequestFactory = TestIAPSKProductsRequestFactory()
    IAPEventResolver.configuredDependencies = .init(
      gateKeeperManager: TestGateKeeperManager.self,
      iapSKProductRequestFactory: iapSKProductRequestFactory
    )
    dedupeProcessor = IAPDedupeProcessor.shared
    dedupeProcessor.disable()
    TestGateKeeperManager.gateKeepers["app_events_if_auto_log_subs"] = true
  }

  override func tearDown() {
    dedupeProcessor.disable()
    IAPTransactionObserver.shared.stopObserving()
    TestGateKeeperManager.gateKeepers["app_events_if_auto_log_subs"] = false
    super.tearDown()
  }

  func testEnableDisable() {
    XCTAssertFalse(dedupeProcessor.isEnabled)
    dedupeProcessor.enable()
    XCTAssertTrue(dedupeProcessor.isEnabled)
    dedupeProcessor.disable()
    XCTAssertFalse(dedupeProcessor.isEnabled)
  }

  func testShouldDedupePurchaseEvent() {
    XCTAssertTrue(dedupeProcessor.shouldDedupeEvent(.purchased))
  }

  func testShouldDedupeSubscribeEvent() {
    XCTAssertTrue(dedupeProcessor.shouldDedupeEvent(.subscribe))
  }

  func testShouldDedupeStartTrialEvent() {
    XCTAssertTrue(dedupeProcessor.shouldDedupeEvent(.startTrial))
  }

  func testShouldNotDedupeRestoredEvent() {
    XCTAssertFalse(dedupeProcessor.shouldDedupeEvent(.purchaseRestored))
  }

  func testAreDuplicatesContentID() {
    let implicitEvent = DedupableEvent(
      eventName: .purchased,
      valueToSum: 10,
      parameters: [
        "fb_currency": "USD",
        "fb_content_id": "12345",
        "fb_transaction_date": "2024-10-20 19:02:50Z",
      ],
      isImplicitEvent: true
    )
    let manualEvent = DedupableEvent(
      eventName: .purchased,
      valueToSum: 10,
      parameters: [
        "fb_currency": "USD",
        "fb_content_id": "12345",
        "_logTime": 1729450978,
      ],
      isImplicitEvent: false
    )
    guard let dedupKey = IAPDedupeProcessor.areDuplicates(
      implicitEvent: implicitEvent,
      manualEvent: manualEvent,
      dedupConfiguration: prodDedupConfig
    ) else {
      XCTFail("Should have dedupe key")
      return
    }
    XCTAssertEqual(dedupKey, "fb_content_id")
  }

  func testAreDuplicatesContentIDWithAlternateValue() {
    let implicitEvent = DedupableEvent(
      eventName: .purchased,
      valueToSum: 10,
      parameters: [
        "fb_currency": "USD",
        "fb_content_id": "12345",
        "fb_transaction_date": "2024-10-20 19:02:50Z",
      ],
      isImplicitEvent: true
    )
    let manualEvent = DedupableEvent(
      eventName: .purchased,
      valueToSum: 0,
      parameters: [
        "fb_currency": "USD",
        "fb_product_price_amount": 10,
        "fb_content_id": "12345",
        "_logTime": 1729450978,
      ],
      isImplicitEvent: false
    )
    guard let dedupKey = IAPDedupeProcessor.areDuplicates(
      implicitEvent: implicitEvent,
      manualEvent: manualEvent,
      dedupConfiguration: prodDedupConfig
    ) else {
      XCTFail("Should have dedupe key")
      return
    }
    XCTAssertEqual(dedupKey, "fb_content_id")
  }

  func testAreDuplicatesContentIDWithAlternateCurrency() {
    let implicitEvent = DedupableEvent(
      eventName: .purchased,
      valueToSum: 10,
      parameters: [
        "fb_currency": "USD",
        "fb_content_id": "12345",
        "fb_transaction_date": "2024-10-20 19:02:50Z",
      ],
      isImplicitEvent: true
    )
    let manualEvent = DedupableEvent(
      eventName: .purchased,
      valueToSum: 10,
      parameters: [
        "fb_product_price_currency": "USD",
        "fb_content_id": "12345",
        "_logTime": 1729450978,
      ],
      isImplicitEvent: false
    )
    guard let dedupKey = IAPDedupeProcessor.areDuplicates(
      implicitEvent: implicitEvent,
      manualEvent: manualEvent,
      dedupConfiguration: prodDedupConfig
    ) else {
      XCTFail("Should have dedupe key")
      return
    }
    XCTAssertEqual(dedupKey, "fb_content_id")
  }

  func testAreDuplicatesProductItemID() {
    let implicitEvent = DedupableEvent(
      eventName: .purchased,
      valueToSum: 10,
      parameters: [
        "fb_currency": "USD",
        "fb_content_id": "12345",
        "fb_transaction_date": "2024-10-20 19:02:50Z",
      ],
      isImplicitEvent: true
    )
    let manualEvent = DedupableEvent(
      eventName: .purchased,
      valueToSum: 10,
      parameters: [
        "fb_currency": "USD",
        "fb_product_item_id": "12345",
        "_logTime": "1729450978",
      ],
      isImplicitEvent: false
    )
    guard let dedupKey = IAPDedupeProcessor.areDuplicates(
      implicitEvent: implicitEvent,
      manualEvent: manualEvent,
      dedupConfiguration: prodDedupConfig
    ) else {
      XCTFail("Should have dedupe key")
      return
    }
    XCTAssertEqual(dedupKey, "fb_product_item_id")
  }

  func testAreDuplicatesTestKey() {
    let implicitEvent = DedupableEvent(
      eventName: .purchased,
      valueToSum: 10,
      parameters: [
        "fb_currency": "USD",
        "iap_test_key_1": "12345",
        "fb_transaction_date": "2024-10-20 19:02:50Z",
      ],
      isImplicitEvent: true
    )
    let manualEvent = DedupableEvent(
      eventName: .purchased,
      valueToSum: 10,
      parameters: [
        "fb_currency": "USD",
        "iap_test_key_3": "12345",
        "_logTime": 1729450978,
      ],
      isImplicitEvent: false
    )
    guard let dedupKey = IAPDedupeProcessor.areDuplicates(
      implicitEvent: implicitEvent,
      manualEvent: manualEvent,
      dedupConfiguration: testDedupConfig
    ) else {
      XCTFail("Should have dedupe key")
      return
    }
    XCTAssertEqual(dedupKey, "iap_test_key_3")
  }

  func testAreNotDuplicatesEventName() {
    let implicitEvent = DedupableEvent(
      eventName: .purchased,
      valueToSum: 10,
      parameters: [
        "fb_currency": "USD",
        "fb_content_id": "12345",
        "fb_transaction_date": "2024-10-20 19:02:45Z",
      ],
      isImplicitEvent: true
    )
    let manualEvent = DedupableEvent(
      eventName: .subscribe,
      valueToSum: 10,
      parameters: [
        "fb_currency": "USD",
        "fb_content_id": "12345",
        "_logTime": 1729450978,
      ],
      isImplicitEvent: false
    )
    let dedupKey = IAPDedupeProcessor.areDuplicates(
      implicitEvent: implicitEvent,
      manualEvent: manualEvent,
      dedupConfiguration: prodDedupConfig
    )
    XCTAssertNil(dedupKey)
  }

  func testAreNotDuplicatesValue() {
    let implicitEvent = DedupableEvent(
      eventName: .purchased,
      valueToSum: 10,
      parameters: [
        "fb_currency": "USD",
        "fb_content_id": "12345",
        "fb_transaction_date": "2024-10-20 19:02:45Z",
      ],
      isImplicitEvent: true
    )
    let manualEvent = DedupableEvent(
      eventName: .purchased,
      valueToSum: 20,
      parameters: [
        "fb_currency": "USD",
        "fb_content_id": "12345",
        "_logTime": 1729450978,
      ],
      isImplicitEvent: false
    )
    let dedupKey = IAPDedupeProcessor.areDuplicates(
      implicitEvent: implicitEvent,
      manualEvent: manualEvent,
      dedupConfiguration: prodDedupConfig
    )
    XCTAssertNil(dedupKey)
  }

  func testAreNotDuplicatesCurrency() {
    let implicitEvent = DedupableEvent(
      eventName: .purchased,
      valueToSum: 10,
      parameters: [
        "fb_currency": "USD",
        "fb_content_id": "12345",
        "fb_transaction_date": "2024-10-20 19:02:45Z",
      ],
      isImplicitEvent: true
    )
    let manualEvent = DedupableEvent(
      eventName: .purchased,
      valueToSum: 10,
      parameters: [
        "fb_currency": "EUR",
        "fb_content_id": "12345",
        "_logTime": 1729450978,
      ],
      isImplicitEvent: false
    )
    let dedupKey = IAPDedupeProcessor.areDuplicates(
      implicitEvent: implicitEvent,
      manualEvent: manualEvent,
      dedupConfiguration: prodDedupConfig
    )
    XCTAssertNil(dedupKey)
  }

  func testAreNotDuplicatesTime() {
    let implicitEvent = DedupableEvent(
      eventName: .purchased,
      valueToSum: 10,
      parameters: [
        "fb_currency": "USD",
        "fb_content_id": "12345",
        "fb_transaction_date": "2024-10-19 19:02:45Z",
      ],
      isImplicitEvent: true
    )
    let manualEvent = DedupableEvent(
      eventName: .purchased,
      valueToSum: 10,
      parameters: [
        "fb_currency": "USD",
        "fb_content_id": "12345",
        "_logTime": 1729450978,
      ],
      isImplicitEvent: false
    )
    let dedupKey = IAPDedupeProcessor.areDuplicates(
      implicitEvent: implicitEvent,
      manualEvent: manualEvent,
      dedupConfiguration: prodDedupConfig
    )
    XCTAssertNil(dedupKey)
  }

  func testAreNotDuplicatesIAPKey() {
    let implicitEvent = DedupableEvent(
      eventName: .purchased,
      valueToSum: 10,
      parameters: [
        "fb_currency": "USD",
        "fb_content_id": "12345",
        "fb_transaction_date": "2024-10-20 19:02:45Z",
      ],
      isImplicitEvent: true
    )
    let manualEvent = DedupableEvent(
      eventName: .purchased,
      valueToSum: 10,
      parameters: [
        "fb_currency": "USD",
        "fb_content_id": "123456",
        "_logTime": 1729450978,
      ],
      isImplicitEvent: false
    )
    let dedupKey = IAPDedupeProcessor.areDuplicates(
      implicitEvent: implicitEvent,
      manualEvent: manualEvent,
      dedupConfiguration: prodDedupConfig
    )
    XCTAssertNil(dedupKey)
  }

  func testAreNotDuplicatesEmptyIAPKey() {
    let implicitEvent = DedupableEvent(
      eventName: .purchased,
      valueToSum: 10,
      parameters: [
        "fb_currency": "USD",
        "fb_content_id": "",
        "fb_transaction_date": "2024-10-20 19:02:45Z",
      ],
      isImplicitEvent: true
    )
    let manualEvent = DedupableEvent(
      eventName: .purchased,
      valueToSum: 10,
      parameters: [
        "fb_currency": "USD",
        "fb_content_id": "",
        "_logTime": 1729450978,
      ],
      isImplicitEvent: false
    )
    let dedupKey = IAPDedupeProcessor.areDuplicates(
      implicitEvent: implicitEvent,
      manualEvent: manualEvent,
      dedupConfiguration: prodDedupConfig
    )
    XCTAssertNil(dedupKey)
  }
}

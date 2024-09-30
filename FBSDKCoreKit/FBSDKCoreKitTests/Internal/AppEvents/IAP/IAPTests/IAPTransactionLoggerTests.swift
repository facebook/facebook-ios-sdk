/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit
@testable import IAPTestsHostApp

import StoreKitTest
import TestTools
import XCTest

final class IAPTransactionLoggerTests: StoreKitTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var iapLogger: IAPTransactionLogger!
  var eventLogger: TestEventLogger!
  var dateFormatter: DateFormatter!
  var iapSKProductRequestFactory: TestIAPSKProductsRequestFactory!
  // swiftlint:enable implicitly_unwrapped_optional
  let autoLogSubscriptionGK = "app_events_if_auto_log_subs"

  override func setUp() async throws {
    try await super.setUp()
    dateFormatter = DateFormatter()
    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
    IAPTransactionCache.shared.reset()
    TestGateKeeperManager.gateKeepers[autoLogSubscriptionGK] = true
    eventLogger = TestEventLogger()
    iapSKProductRequestFactory = TestIAPSKProductsRequestFactory()
    IAPTransactionLogger.configuredDependencies = .init(
      eventLogger: eventLogger
    )
    IAPEventResolver.configuredDependencies = .init(
      gateKeeperManager: TestGateKeeperManager.self,
      iapSKProductRequestFactory: iapSKProductRequestFactory
    )
    iapLogger = IAPTransactionLogger()
  }
}

// MARK: - Store Kit 2

@available(iOS 15.0, *)
extension IAPTransactionLoggerTests {
  private func executeTransactionFor(_ productID: String) async -> (IAPTransaction, Product)? {
    guard let products =
      try? await Product.products(for: [productID]),
      let product = products.first else {
      return nil
    }
    guard let result = try? await product.purchase() else {
      return nil
    }
    guard let iapTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return nil
    }
    await iapTransaction.transaction.finish()
    return (iapTransaction, product)
  }

  // MARK: - New Subscriptions

  func testLogNewSubscriptionTransactionStartTrial() async {
    guard let (iapTransaction, product) =
      await executeTransactionFor(Self.ProductIdentifiers.autoRenewingSubscription2.rawValue) else {
      return
    }
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .startTrial)
    XCTAssertEqual(eventLogger.capturedValueToSum, 0)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: String(iapTransaction.transaction.originalID),
        eventName: .startTrial
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, product.id)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: iapTransaction.transaction.purchaseDate)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, product.displayName)
    XCTAssertEqual(capturedParameters[.description] as? String, product.description)
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, String(iapTransaction.transaction.id))
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "P1Y")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "1")
    XCTAssertEqual(capturedParameters[.hasFreeTrial] as? String, "1")
    XCTAssertEqual(capturedParameters[.trialPeriod] as? String, "P6M")
    XCTAssertEqual(capturedParameters[.trialPrice] as? Double, 0)
  }

  func testLogNewSubscriptionTransactionNonRenewable() async {
    guard let (iapTransaction, product) =
      await executeTransactionFor(Self.ProductIdentifiers.nonRenewingSubscription1.rawValue) else {
      return
    }
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .purchased)
    XCTAssertEqual(eventLogger.capturedValueToSum, 5)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: String(iapTransaction.transaction.originalID),
        eventName: .purchased
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, product.id)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: iapTransaction.transaction.purchaseDate)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, product.displayName)
    XCTAssertEqual(capturedParameters[.description] as? String, product.description)
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, String(iapTransaction.transaction.id))
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "inapp")
    XCTAssertNil(capturedParameters[.subscriptionPeriod])
    XCTAssertNil(capturedParameters[.isStartTrial])
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogNewSubscriptionTransactionAutoRenewable() async {
    guard let (iapTransaction, product) =
      await executeTransactionFor(Self.ProductIdentifiers.autoRenewingSubscription1.rawValue) else {
      return
    }
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .subscribe)
    XCTAssertEqual(eventLogger.capturedValueToSum, 2)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: String(iapTransaction.transaction.originalID),
        eventName: .subscribe
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, product.id)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: iapTransaction.transaction.purchaseDate)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, product.displayName)
    XCTAssertEqual(capturedParameters[.description] as? String, product.description)
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, String(iapTransaction.transaction.id))
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "P1Y")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "0")
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogNewSubscriptionTransactionWithStartTrialInCache() async {
    guard let (iapTransaction, product) =
      await executeTransactionFor(Self.ProductIdentifiers.autoRenewingSubscription1.rawValue) else {
      return
    }
    IAPTransactionCache.shared.addTransaction(
      transactionID: String(iapTransaction.transaction.id),
      eventName: .startTrial
    )
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .subscribe)
    XCTAssertEqual(eventLogger.capturedValueToSum, 2)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: String(iapTransaction.transaction.originalID),
        eventName: .subscribe
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, product.id)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: iapTransaction.transaction.purchaseDate)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, product.displayName)
    XCTAssertEqual(capturedParameters[.description] as? String, product.description)
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, String(iapTransaction.transaction.id))
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "P1Y")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "0")
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogNewSubscriptionTransactionGKDisabled() async {
    TestGateKeeperManager.gateKeepers[autoLogSubscriptionGK] = false
    guard let (iapTransaction, product) =
      await executeTransactionFor(Self.ProductIdentifiers.autoRenewingSubscription1.rawValue) else {
      return
    }
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .purchased)
    XCTAssertEqual(eventLogger.capturedValueToSum, 2)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: String(iapTransaction.transaction.originalID),
        eventName: .purchased
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, product.id)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: iapTransaction.transaction.purchaseDate)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, product.displayName)
    XCTAssertEqual(capturedParameters[.description] as? String, product.description)
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, String(iapTransaction.transaction.id))
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "P1Y")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "0")
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogNewSubscriptionTransactionStartTrialWithStartTrialInCache() async {
    guard let (iapTransaction, _) =
      await executeTransactionFor(Self.ProductIdentifiers.autoRenewingSubscription2.rawValue) else {
      return
    }
    IAPTransactionCache.shared.addTransaction(
      transactionID: String(iapTransaction.transaction.originalID),
      eventName: .startTrial
    )
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertNil(eventLogger.capturedEventName)
    XCTAssertNil(eventLogger.capturedValueToSum)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: String(iapTransaction.transaction.id),
        eventName: .startTrial
      )
    )
    XCTAssertNil(eventLogger.capturedParameters)
  }

  func testLogNewSubscriptionTransactionWithSubscribeInCache() async {
    guard let (iapTransaction, _) =
      await executeTransactionFor(Self.ProductIdentifiers.autoRenewingSubscription1.rawValue) else {
      return
    }
    IAPTransactionCache.shared.addTransaction(
      transactionID: String(iapTransaction.transaction.originalID),
      eventName: .subscribe
    )
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertNil(eventLogger.capturedEventName)
    XCTAssertNil(eventLogger.capturedValueToSum)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: String(iapTransaction.transaction.id),
        eventName: .subscribe
      )
    )
    XCTAssertNil(eventLogger.capturedParameters)
  }

  func testLogNewSubscriptionTransactionWithRestoreInCache() async {
    guard let (iapTransaction, _) =
      await executeTransactionFor(Self.ProductIdentifiers.autoRenewingSubscription1.rawValue) else {
      return
    }
    IAPTransactionCache.shared.addTransaction(
      transactionID: String(iapTransaction.transaction.originalID),
      eventName: .subscribeRestore
    )
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertNil(eventLogger.capturedEventName)
    XCTAssertNil(eventLogger.capturedValueToSum)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: String(iapTransaction.transaction.id),
        eventName: .subscribe
      )
    )
    XCTAssertNil(eventLogger.capturedParameters)
  }

  @available(iOS 17.0, *)
  func testLogNewSubscriptionTransactionRenewal() async {
    testSession.timeRate = .oneRenewalEveryTwoSeconds
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.autoRenewingSubscription1.rawValue]),
      let product = products.first else {
      return
    }
    guard let result = try? await product.purchase() else {
      return
    }
    guard let originalTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return
    }
    await originalTransaction.transaction.finish()
    await iapLogger.logNewTransaction(originalTransaction)
    sleep(3)
    let transactions = await Transaction.all.getValues()
    guard let renewalTransaction = transactions.first?.iapTransaction else {
      return
    }
    await iapLogger.logNewTransaction(renewalTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .subscribe)
    XCTAssertEqual(eventLogger.capturedValueToSum, 2)
    XCTAssertEqual(originalTransaction.transaction.id, renewalTransaction.transaction.originalID)
    XCTAssertNotEqual(renewalTransaction.transaction.originalID, renewalTransaction.transaction.id)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: String(renewalTransaction.transaction.originalID),
        eventName: .subscribe
      )
    )
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: String(renewalTransaction.transaction.id),
        eventName: .subscribe
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, product.id)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: originalTransaction.transaction.purchaseDate)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, product.displayName)
    XCTAssertEqual(capturedParameters[.description] as? String, product.description)
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, String(originalTransaction.transaction.id))
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "P1Y")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "0")
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  // MARK: - New Purchases

  func testLogNewPurchaseTransactionConsumable() async {
    guard let (iapTransaction, product) =
      await executeTransactionFor(Self.ProductIdentifiers.consumableProduct1.rawValue) else {
      return
    }
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .purchased)
    XCTAssertEqual(eventLogger.capturedValueToSum, 10)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: String(iapTransaction.transaction.originalID),
        eventName: .purchased
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, product.id)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: iapTransaction.transaction.purchaseDate)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, product.displayName)
    XCTAssertEqual(capturedParameters[.description] as? String, product.description)
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, String(iapTransaction.transaction.id))
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "inapp")
    XCTAssertNil(capturedParameters[.subscriptionPeriod])
    XCTAssertNil(capturedParameters[.isStartTrial])
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogNewPurchaseTransactionNonConsumable() async {
    guard let (iapTransaction, product) =
      await executeTransactionFor(Self.ProductIdentifiers.nonConsumableProduct1.rawValue) else {
      return
    }
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .purchased)
    XCTAssertEqual(eventLogger.capturedValueToSum, 0.99)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: String(iapTransaction.transaction.originalID),
        eventName: .purchased
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, product.id)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: iapTransaction.transaction.purchaseDate)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, product.displayName)
    XCTAssertEqual(capturedParameters[.description] as? String, product.description)
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, String(iapTransaction.transaction.id))
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "inapp")
    XCTAssertNil(capturedParameters[.subscriptionPeriod])
    XCTAssertNil(capturedParameters[.isStartTrial])
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogNewPurchaseTransactionWithPurchaseInCache() async {
    guard let (iapTransaction, _) =
      await executeTransactionFor(Self.ProductIdentifiers.nonConsumableProduct1.rawValue) else {
      return
    }
    IAPTransactionCache.shared.addTransaction(
      transactionID: String(iapTransaction.transaction.originalID),
      eventName: .purchased
    )
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertNil(eventLogger.capturedEventName)
    XCTAssertNil(eventLogger.capturedValueToSum)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: String(iapTransaction.transaction.id),
        eventName: .purchased
      )
    )
    XCTAssertNil(eventLogger.capturedParameters)
  }

  // MARK: - Restored Subscriptions

  func testLogRestoredSubscriptionTransactionAutoRenewableStartTrial() async {
    guard let (iapTransaction, product) =
      await executeTransactionFor(Self.ProductIdentifiers.autoRenewingSubscription2.rawValue) else {
      return
    }
    await iapLogger.logRestoredTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .subscribeRestore)
    XCTAssertEqual(eventLogger.capturedValueToSum, 0)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: String(iapTransaction.transaction.originalID),
        eventName: .subscribeRestore
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, product.id)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: iapTransaction.transaction.purchaseDate)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, product.displayName)
    XCTAssertEqual(capturedParameters[.description] as? String, product.description)
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, String(iapTransaction.transaction.id))
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "P1Y")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "1")
    XCTAssertEqual(capturedParameters[.hasFreeTrial] as? String, "1")
    XCTAssertEqual(capturedParameters[.trialPeriod] as? String, "P6M")
    XCTAssertEqual(capturedParameters[.trialPrice] as? Double, 0)
  }

  func testLogRestoredSubscriptionTransactionNonRenewable() async {
    guard let (iapTransaction, product) =
      await executeTransactionFor(Self.ProductIdentifiers.nonRenewingSubscription1.rawValue) else {
      return
    }
    await iapLogger.logRestoredTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .purchaseRestored)
    XCTAssertEqual(eventLogger.capturedValueToSum, 5)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: String(iapTransaction.transaction.originalID),
        eventName: .purchaseRestored
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, product.id)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: iapTransaction.transaction.purchaseDate)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, product.displayName)
    XCTAssertEqual(capturedParameters[.description] as? String, product.description)
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, String(iapTransaction.transaction.id))
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "inapp")
    XCTAssertNil(capturedParameters[.subscriptionPeriod])
    XCTAssertNil(capturedParameters[.isStartTrial])
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogRestoredSubscriptionTransactionAutoRenewable() async {
    guard let (iapTransaction, product) =
      await executeTransactionFor(Self.ProductIdentifiers.autoRenewingSubscription1.rawValue) else {
      return
    }
    await iapLogger.logRestoredTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .subscribeRestore)
    XCTAssertEqual(eventLogger.capturedValueToSum, 2)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: String(iapTransaction.transaction.originalID),
        eventName: .subscribeRestore
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, product.id)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: iapTransaction.transaction.purchaseDate)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, product.displayName)
    XCTAssertEqual(capturedParameters[.description] as? String, product.description)
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, String(iapTransaction.transaction.id))
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "P1Y")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "0")
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogRestoredSubscriptionTransactionWithRestoredInCache() async {
    guard let (iapTransaction, _) =
      await executeTransactionFor(Self.ProductIdentifiers.autoRenewingSubscription1.rawValue) else {
      return
    }
    IAPTransactionCache.shared.addTransaction(
      transactionID: String(iapTransaction.transaction.originalID),
      eventName: .subscribeRestore
    )
    await iapLogger.logRestoredTransaction(iapTransaction)
    XCTAssertNil(eventLogger.capturedEventName)
    XCTAssertNil(eventLogger.capturedValueToSum)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: String(iapTransaction.transaction.id),
        eventName: .subscribeRestore
      )
    )
    XCTAssertNil(eventLogger.capturedParameters)
  }

  func testLogRestoredSubscriptionTransactionGKDisabled() async {
    TestGateKeeperManager.gateKeepers[autoLogSubscriptionGK] = false
    guard let (iapTransaction, product) =
      await executeTransactionFor(Self.ProductIdentifiers.autoRenewingSubscription1.rawValue) else {
      return
    }
    await iapLogger.logRestoredTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .purchaseRestored)
    XCTAssertEqual(eventLogger.capturedValueToSum, 2)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: String(iapTransaction.transaction.originalID),
        eventName: .purchaseRestored
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, product.id)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: iapTransaction.transaction.purchaseDate)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, product.displayName)
    XCTAssertEqual(capturedParameters[.description] as? String, product.description)
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, String(iapTransaction.transaction.id))
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "P1Y")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "0")
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  // MARK: - Restored Purchases

  func testLogRestoredPurchaseTransactionConsumable() async {
    guard let (iapTransaction, product) =
      await executeTransactionFor(Self.ProductIdentifiers.consumableProduct1.rawValue) else {
      return
    }
    await iapLogger.logRestoredTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .purchaseRestored)
    XCTAssertEqual(eventLogger.capturedValueToSum, 10)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: String(iapTransaction.transaction.originalID),
        eventName: .purchaseRestored
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, product.id)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: iapTransaction.transaction.purchaseDate)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, product.displayName)
    XCTAssertEqual(capturedParameters[.description] as? String, product.description)
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, String(iapTransaction.transaction.id))
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "inapp")
    XCTAssertNil(capturedParameters[.subscriptionPeriod])
    XCTAssertNil(capturedParameters[.isStartTrial])
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogRestoredPurchaseTransactionNonConsumable() async {
    guard let (iapTransaction, product) =
      await executeTransactionFor(Self.ProductIdentifiers.nonConsumableProduct1.rawValue) else {
      return
    }
    await iapLogger.logRestoredTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .purchaseRestored)
    XCTAssertEqual(eventLogger.capturedValueToSum, 0.99)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: String(iapTransaction.transaction.originalID),
        eventName: .purchaseRestored
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, product.id)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: iapTransaction.transaction.purchaseDate)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, product.displayName)
    XCTAssertEqual(capturedParameters[.description] as? String, product.description)
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, String(iapTransaction.transaction.id))
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "inapp")
    XCTAssertNil(capturedParameters[.subscriptionPeriod])
    XCTAssertNil(capturedParameters[.isStartTrial])
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogRestoredPurchaseTransactionRestoredInCache() async {
    guard let (iapTransaction, _) =
      await executeTransactionFor(Self.ProductIdentifiers.nonConsumableProduct1.rawValue) else {
      return
    }
    IAPTransactionCache.shared.addTransaction(
      transactionID: String(iapTransaction.transaction.originalID),
      eventName: .purchaseRestored
    )
    await iapLogger.logRestoredTransaction(iapTransaction)
    XCTAssertNil(eventLogger.capturedEventName)
    XCTAssertNil(eventLogger.capturedValueToSum)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: String(iapTransaction.transaction.id),
        eventName: .purchaseRestored
      )
    )
    XCTAssertNil(eventLogger.capturedParameters)
  }

  // MARK: - Duplicates

  func testLogDuplicatePurchaseEventFirstOneShouldSucceed() async {
    guard let (iapTransaction, product) =
      await executeTransactionFor(Self.ProductIdentifiers.nonConsumableProduct1.rawValue) else {
      return
    }
    await iapLogger.logNewTransaction(iapTransaction)
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .purchased)
    XCTAssertEqual(eventLogger.capturedValueToSum, 0.99)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: String(iapTransaction.transaction.id),
        eventName: .purchased
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, product.id)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: iapTransaction.transaction.purchaseDate)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, product.displayName)
    XCTAssertEqual(capturedParameters[.description] as? String, product.description)
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, String(iapTransaction.transaction.id))
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "inapp")
    XCTAssertNil(capturedParameters[.subscriptionPeriod])
    XCTAssertNil(capturedParameters[.isStartTrial])
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogPurchaseRestoredEventAndThenPurchaseEventPurchaseRestoredShouldSucceed() async {
    guard let (iapTransaction, product) =
      await executeTransactionFor(Self.ProductIdentifiers.nonConsumableProduct1.rawValue) else {
      return
    }
    await iapLogger.logRestoredTransaction(iapTransaction)
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .purchaseRestored)
    XCTAssertEqual(eventLogger.capturedValueToSum, 0.99)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: String(iapTransaction.transaction.originalID),
        eventName: .purchaseRestored
      )
    )
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: String(iapTransaction.transaction.id),
        eventName: .purchased
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, product.id)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: iapTransaction.transaction.purchaseDate)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, product.displayName)
    XCTAssertEqual(capturedParameters[.description] as? String, product.description)
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, String(iapTransaction.transaction.id))
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "inapp")
    XCTAssertNil(capturedParameters[.subscriptionPeriod])
    XCTAssertNil(capturedParameters[.isStartTrial])
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogDuplicateSubscriptionEventFirstOneShouldSucceed() async {
    guard let (iapTransaction, product) =
      await executeTransactionFor(Self.ProductIdentifiers.autoRenewingSubscription1.rawValue) else {
      return
    }
    await iapLogger.logNewTransaction(iapTransaction)
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .subscribe)
    XCTAssertEqual(eventLogger.capturedValueToSum, 2)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: String(iapTransaction.transaction.id),
        eventName: .subscribe
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, product.id)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: iapTransaction.transaction.purchaseDate)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, product.displayName)
    XCTAssertEqual(capturedParameters[.description] as? String, product.description)
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, String(iapTransaction.transaction.id))
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "P1Y")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "0")
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogSubscriptionRestoredEventAndThenSubscriptionEventSubscriptionRestoredShouldSucceed() async {
    guard let (iapTransaction, product) =
      await executeTransactionFor(Self.ProductIdentifiers.autoRenewingSubscription1.rawValue) else {
      return
    }
    await iapLogger.logRestoredTransaction(iapTransaction)
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .subscribeRestore)
    XCTAssertEqual(eventLogger.capturedValueToSum, 2)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: String(iapTransaction.transaction.originalID),
        eventName: .subscribeRestore
      )
    )
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: String(iapTransaction.transaction.id),
        eventName: .subscribe
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, product.id)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: iapTransaction.transaction.purchaseDate)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, product.displayName)
    XCTAssertEqual(capturedParameters[.description] as? String, product.description)
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, String(iapTransaction.transaction.id))
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "P1Y")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "0")
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }
}

// MARK: - Store Kit 1

@available(iOS 12.2, *)
extension IAPTransactionLoggerTests {

  // MARK: - New Subscriptions

  func testLogNewSubscriptionTransactionStartTrialWithStoreKit1() {
    let productID = Self.ProductIdentifiers.autoRenewingSubscription2
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let now = Date()
    let sampleDiscount = SKPaymentDiscount(
      identifier: "FreeTrial",
      keyIdentifier: "key",
      nonce: UUID(),
      signature: "signature",
      timestamp: 1
    )
    let transactionID = "0"
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1, discount: sampleDiscount)
    let transaction = TestPaymentTransaction(identifier: transactionID, state: .purchased, date: now, payment: payment)
    iapLogger.logTransaction(transaction)
    XCTAssertEqual(eventLogger.capturedEventName, .startTrial)
    XCTAssertEqual(eventLogger.capturedValueToSum, 0)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: transactionID,
        eventName: .startTrial
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, productID.rawValue)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: now)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, "")
    XCTAssertEqual(capturedParameters[.description] as? String, "")
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, transactionID)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "P1Y")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "1")
    XCTAssertEqual(capturedParameters[.hasFreeTrial] as? String, "1")
    XCTAssertEqual(capturedParameters[.trialPeriod] as? String, "P6M")
    XCTAssertEqual(capturedParameters[.trialPrice] as? Double, 0)
  }

  func testLogNewSubscriptionTransactionNonRenewableWithStoreKit1() {
    let productID = Self.ProductIdentifiers.nonRenewingSubscription1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let now = Date()
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transactionID = "0"
    let transaction = TestPaymentTransaction(identifier: transactionID, state: .purchased, date: now, payment: payment)
    iapLogger.logTransaction(transaction)
    XCTAssertEqual(eventLogger.capturedEventName, .purchased)
    XCTAssertEqual(eventLogger.capturedValueToSum, 5)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: transactionID,
        eventName: .purchased
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, productID.rawValue)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: now)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, "")
    XCTAssertEqual(capturedParameters[.description] as? String, "")
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, transactionID)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "inapp")
    XCTAssertNil(capturedParameters[.subscriptionPeriod])
    XCTAssertNil(capturedParameters[.isStartTrial])
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogNewSubscriptionTransactionAutoRenewableWithStoreKit1() {
    let transactionID = "0"
    let productID = Self.ProductIdentifiers.autoRenewingSubscription1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let now = Date()
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(identifier: transactionID, state: .purchased, date: now, payment: payment)
    iapLogger.logTransaction(transaction)
    XCTAssertEqual(eventLogger.capturedEventName, .subscribe)
    XCTAssertEqual(eventLogger.capturedValueToSum, 2)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: transactionID,
        eventName: .subscribe
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, productID.rawValue)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: now)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, "")
    XCTAssertEqual(capturedParameters[.description] as? String, "")
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, transactionID)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "P1Y")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "0")
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogNewSubscriptionTransactionWithStartTrialInCacheWithStoreKit1() {
    let transactionID = "0"
    let productID = Self.ProductIdentifiers.autoRenewingSubscription1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let now = Date()
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(identifier: transactionID, state: .purchased, date: now, payment: payment)
    IAPTransactionCache.shared.addTransaction(
      transactionID: transactionID,
      eventName: .startTrial
    )
    iapLogger.logTransaction(transaction)
    XCTAssertEqual(eventLogger.capturedEventName, .subscribe)
    XCTAssertEqual(eventLogger.capturedValueToSum, 2)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: transactionID,
        eventName: .subscribe
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, productID.rawValue)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: now)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, "")
    XCTAssertEqual(capturedParameters[.description] as? String, "")
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, transactionID)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "P1Y")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "0")
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogNewSubscriptionTransactionGKDisabledWithStoreKit1() {
    TestGateKeeperManager.gateKeepers[autoLogSubscriptionGK] = false
    let transactionID = "0"
    let productID = Self.ProductIdentifiers.autoRenewingSubscription1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let now = Date()
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(identifier: transactionID, state: .purchased, date: now, payment: payment)
    iapLogger.logTransaction(transaction)
    XCTAssertEqual(eventLogger.capturedEventName, .purchased)
    XCTAssertEqual(eventLogger.capturedValueToSum, 2)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: transactionID,
        eventName: .purchased
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, productID.rawValue)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: now)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, "")
    XCTAssertEqual(capturedParameters[.description] as? String, "")
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, transactionID)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "P1Y")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "0")
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogNewSubscriptionTransactionStartTrialWithStartTrialInCacheWithStoreKit1() {
    let transactionID = "0"
    let productID = Self.ProductIdentifiers.autoRenewingSubscription2
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let now = Date()
    let sampleDiscount = SKPaymentDiscount(
      identifier: "FreeTrial",
      keyIdentifier: "key",
      nonce: UUID(),
      signature: "signature",
      timestamp: 1
    )
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1, discount: sampleDiscount)
    let transaction = TestPaymentTransaction(identifier: transactionID, state: .purchased, date: now, payment: payment)
    IAPTransactionCache.shared.addTransaction(
      transactionID: transactionID,
      eventName: .startTrial
    )
    iapLogger.logTransaction(transaction)
    XCTAssertNil(eventLogger.capturedEventName)
    XCTAssertNil(eventLogger.capturedValueToSum)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: transactionID,
        eventName: .startTrial
      )
    )
    XCTAssertNil(eventLogger.capturedParameters)
  }

  func testLogNewSubscriptionTransactionWithSubscribeInCacheWithStoreKit1() {
    let transactionID = "0"
    let productID = Self.ProductIdentifiers.autoRenewingSubscription1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let now = Date()
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(identifier: transactionID, state: .purchased, date: now, payment: payment)
    IAPTransactionCache.shared.addTransaction(
      transactionID: transactionID,
      eventName: .subscribe
    )
    iapLogger.logTransaction(transaction)
    XCTAssertNil(eventLogger.capturedEventName)
    XCTAssertNil(eventLogger.capturedValueToSum)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: transactionID,
        eventName: .subscribe
      )
    )
    XCTAssertNil(eventLogger.capturedParameters)
  }

  func testLogNewSubscriptionTransactionWithRestoreInCacheWithStoreKit1() {
    let transactionID = "0"
    let productID = Self.ProductIdentifiers.autoRenewingSubscription1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let now = Date()
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(identifier: transactionID, state: .purchased, date: now, payment: payment)
    IAPTransactionCache.shared.addTransaction(
      transactionID: transactionID,
      eventName: .subscribeRestore
    )
    iapLogger.logTransaction(transaction)
    XCTAssertNil(eventLogger.capturedEventName)
    XCTAssertNil(eventLogger.capturedValueToSum)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: transactionID,
        eventName: .subscribe
      )
    )
    XCTAssertNil(eventLogger.capturedParameters)
  }

  // MARK: - New Purchases

  func testLogNewPurchaseTransactionConsumableWithStoreKit1() {
    let transactionID = "0"
    let productID = Self.ProductIdentifiers.consumableProduct1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let now = Date()
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 2)
    let transaction = TestPaymentTransaction(identifier: transactionID, state: .purchased, date: now, payment: payment)
    iapLogger.logTransaction(transaction)
    XCTAssertEqual(eventLogger.capturedEventName, .purchased)
    XCTAssertEqual(eventLogger.capturedValueToSum, 20)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: transactionID,
        eventName: .purchased
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, productID.rawValue)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 2)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: now)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, "")
    XCTAssertEqual(capturedParameters[.description] as? String, "")
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, transactionID)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "inapp")
    XCTAssertNil(capturedParameters[.subscriptionPeriod])
    XCTAssertNil(capturedParameters[.isStartTrial])
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogNewPurchaseTransactionNonConsumableWithStoreKit1() {
    let transactionID = "0"
    let productID = Self.ProductIdentifiers.nonRenewingSubscription1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let now = Date()
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(identifier: transactionID, state: .purchased, date: now, payment: payment)
    iapLogger.logTransaction(transaction)
    XCTAssertEqual(eventLogger.capturedEventName, .purchased)
    XCTAssertEqual(eventLogger.capturedValueToSum, 5.0)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: transactionID,
        eventName: .purchased
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, productID.rawValue)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: now)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, "")
    XCTAssertEqual(capturedParameters[.description] as? String, "")
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, transactionID)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "inapp")
    XCTAssertNil(capturedParameters[.subscriptionPeriod])
    XCTAssertNil(capturedParameters[.isStartTrial])
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogNewPurchaseTransactionWithPurchaseInCacheWithStoreKit1() {
    let transactionID = "0"
    let productID = Self.ProductIdentifiers.nonConsumableProduct1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let now = Date()
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(identifier: transactionID, state: .purchased, date: now, payment: payment)
    IAPTransactionCache.shared.addTransaction(
      transactionID: transactionID,
      eventName: .purchased
    )
    iapLogger.logTransaction(transaction)
    XCTAssertNil(eventLogger.capturedEventName)
    XCTAssertNil(eventLogger.capturedValueToSum)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: transactionID,
        eventName: .purchased
      )
    )
    XCTAssertNil(eventLogger.capturedParameters)
  }

  // MARK: - Restored Subscriptions

  func testLogRestoredSubscriptionTransactionAutoRenewableStartTrialWithStoreKit1() {
    let productID = Self.ProductIdentifiers.autoRenewingSubscription2
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let now = Date()
    let sampleDiscount = SKPaymentDiscount(
      identifier: "FreeTrial",
      keyIdentifier: "key",
      nonce: UUID(),
      signature: "signature",
      timestamp: 1
    )
    let transactionID = "0"
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1, discount: sampleDiscount)
    let transaction = TestPaymentTransaction(identifier: transactionID, state: .restored, date: now, payment: payment)
    iapLogger.logTransaction(transaction)
    XCTAssertEqual(eventLogger.capturedEventName, .subscribeRestore)
    XCTAssertEqual(eventLogger.capturedValueToSum, 0)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: transactionID,
        eventName: .subscribeRestore
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, productID.rawValue)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: now)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, "")
    XCTAssertEqual(capturedParameters[.description] as? String, "")
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, transactionID)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "P1Y")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "1")
    XCTAssertEqual(capturedParameters[.hasFreeTrial] as? String, "1")
    XCTAssertEqual(capturedParameters[.trialPeriod] as? String, "P6M")
    XCTAssertEqual(capturedParameters[.trialPrice] as? Double, 0)
  }

  func testLogRestoredSubscriptionTransactionNonRenewableWithStoreKit1() {
    let productID = Self.ProductIdentifiers.nonRenewingSubscription1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let now = Date()
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transactionID = "0"
    let transaction = TestPaymentTransaction(identifier: transactionID, state: .restored, date: now, payment: payment)
    iapLogger.logTransaction(transaction)
    XCTAssertEqual(eventLogger.capturedEventName, .purchaseRestored)
    XCTAssertEqual(eventLogger.capturedValueToSum, 5)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: transactionID,
        eventName: .purchaseRestored
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, productID.rawValue)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: now)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, "")
    XCTAssertEqual(capturedParameters[.description] as? String, "")
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, transactionID)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "inapp")
    XCTAssertNil(capturedParameters[.subscriptionPeriod])
    XCTAssertNil(capturedParameters[.isStartTrial])
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogRestoredSubscriptionTransactionAutoRenewableWithStoreKit1() {
    let transactionID = "0"
    let productID = Self.ProductIdentifiers.autoRenewingSubscription1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let now = Date()
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(identifier: transactionID, state: .restored, date: now, payment: payment)
    iapLogger.logTransaction(transaction)
    XCTAssertEqual(eventLogger.capturedEventName, .subscribeRestore)
    XCTAssertEqual(eventLogger.capturedValueToSum, 2)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: transactionID,
        eventName: .subscribeRestore
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, productID.rawValue)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: now)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, "")
    XCTAssertEqual(capturedParameters[.description] as? String, "")
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, transactionID)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "P1Y")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "0")
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogRestoredSubscriptionTransactionWithRestoredInCacheWithStoreKit1() {
    let transactionID = "0"
    let productID = Self.ProductIdentifiers.autoRenewingSubscription1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let now = Date()
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(identifier: transactionID, state: .restored, date: now, payment: payment)
    IAPTransactionCache.shared.addTransaction(
      transactionID: transactionID,
      eventName: .subscribeRestore
    )
    iapLogger.logTransaction(transaction)
    XCTAssertNil(eventLogger.capturedEventName)
    XCTAssertNil(eventLogger.capturedValueToSum)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: transactionID,
        eventName: .subscribeRestore
      )
    )
    XCTAssertNil(eventLogger.capturedParameters)
  }

  func testLogRestoredSubscriptionTransactionGKDisabledWithStoreKit1() {
    TestGateKeeperManager.gateKeepers[autoLogSubscriptionGK] = false
    let transactionID = "0"
    let productID = Self.ProductIdentifiers.autoRenewingSubscription1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let now = Date()
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(identifier: transactionID, state: .restored, date: now, payment: payment)
    iapLogger.logTransaction(transaction)
    XCTAssertEqual(eventLogger.capturedEventName, .purchaseRestored)
    XCTAssertEqual(eventLogger.capturedValueToSum, 2)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: transactionID,
        eventName: .purchaseRestored
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, productID.rawValue)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: now)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, "")
    XCTAssertEqual(capturedParameters[.description] as? String, "")
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, transactionID)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "P1Y")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "0")
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  // MARK: - Restored Purchases

  func testLogRestoredPurchaseTransactionConsumableWithStoreKit1() {
    let transactionID = "0"
    let productID = Self.ProductIdentifiers.consumableProduct1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let now = Date()
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(identifier: transactionID, state: .restored, date: now, payment: payment)
    iapLogger.logTransaction(transaction)
    XCTAssertEqual(eventLogger.capturedEventName, .purchaseRestored)
    XCTAssertEqual(eventLogger.capturedValueToSum, 10)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: transactionID,
        eventName: .purchaseRestored
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, productID.rawValue)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: now)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, "")
    XCTAssertEqual(capturedParameters[.description] as? String, "")
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, transactionID)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "inapp")
    XCTAssertNil(capturedParameters[.subscriptionPeriod])
    XCTAssertNil(capturedParameters[.isStartTrial])
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogRestoredPurchaseTransactionNonConsumableWithStoreKit1() {
    let transactionID = "0"
    let productID = Self.ProductIdentifiers.nonConsumableProduct1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let now = Date()
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(identifier: transactionID, state: .restored, date: now, payment: payment)
    iapLogger.logTransaction(transaction)
    XCTAssertEqual(eventLogger.capturedEventName, .purchaseRestored)
    XCTAssertEqual(eventLogger.capturedValueToSum, 0.99)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: transactionID,
        eventName: .purchaseRestored
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, productID.rawValue)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: now)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, "")
    XCTAssertEqual(capturedParameters[.description] as? String, "")
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, transactionID)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "inapp")
    XCTAssertNil(capturedParameters[.subscriptionPeriod])
    XCTAssertNil(capturedParameters[.isStartTrial])
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogRestoredPurchaseTransactionRestoredInCacheWithStoreKit1() {
    let transactionID = "0"
    let productID = Self.ProductIdentifiers.nonConsumableProduct1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let now = Date()
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(identifier: transactionID, state: .restored, date: now, payment: payment)
    IAPTransactionCache.shared.addTransaction(
      transactionID: transactionID,
      eventName: .purchaseRestored
    )
    iapLogger.logTransaction(transaction)
    XCTAssertNil(eventLogger.capturedEventName)
    XCTAssertNil(eventLogger.capturedValueToSum)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: transactionID,
        eventName: .purchaseRestored
      )
    )
    XCTAssertNil(eventLogger.capturedParameters)
  }

  // MARK: - Duplicates

  func testLogDuplicatePurchaseEventFirstOneShouldSucceedWithStoreKit1() {
    let transactionID = "0"
    let productID = Self.ProductIdentifiers.nonConsumableProduct1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let now = Date()
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(identifier: transactionID, state: .purchased, date: now, payment: payment)
    iapLogger.logTransaction(transaction)
    iapLogger.logTransaction(transaction)
    XCTAssertEqual(eventLogger.capturedEventName, .purchased)
    XCTAssertEqual(eventLogger.capturedValueToSum, 0.99)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: transactionID,
        eventName: .purchased
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, productID.rawValue)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: now)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, "")
    XCTAssertEqual(capturedParameters[.description] as? String, "")
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, transactionID)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "inapp")
    XCTAssertNil(capturedParameters[.subscriptionPeriod])
    XCTAssertNil(capturedParameters[.isStartTrial])
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogPurchaseRestoredEventAndThenPurchaseEventPurchaseRestoredShouldSucceedWithStoreKit1() {
    let transactionID = "0"
    let productID = Self.ProductIdentifiers.nonConsumableProduct1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let now = Date()
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let restoredTransaction = TestPaymentTransaction(
      identifier: transactionID,
      state: .restored,
      date: now,
      payment: payment
    )
    let newTransaction = TestPaymentTransaction(
      identifier: transactionID,
      state: .purchased,
      date: now,
      payment: payment
    )
    iapLogger.logTransaction(restoredTransaction)
    iapLogger.logTransaction(newTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .purchaseRestored)
    XCTAssertEqual(eventLogger.capturedValueToSum, 0.99)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: transactionID,
        eventName: .purchaseRestored
      )
    )
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: transactionID,
        eventName: .purchased
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, productID.rawValue)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: now)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, "")
    XCTAssertEqual(capturedParameters[.description] as? String, "")
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, transactionID)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "inapp")
    XCTAssertNil(capturedParameters[.subscriptionPeriod])
    XCTAssertNil(capturedParameters[.isStartTrial])
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogDuplicateSubscriptionEventFirstOneShouldSucceedWithStoreKit1() {
    let transactionID = "0"
    let productID = Self.ProductIdentifiers.autoRenewingSubscription1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let now = Date()
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(identifier: transactionID, state: .purchased, date: now, payment: payment)
    iapLogger.logTransaction(transaction)
    iapLogger.logTransaction(transaction)
    XCTAssertEqual(eventLogger.capturedEventName, .subscribe)
    XCTAssertEqual(eventLogger.capturedValueToSum, 2)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: transactionID,
        eventName: .subscribe
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, productID.rawValue)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: now)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, "")
    XCTAssertEqual(capturedParameters[.description] as? String, "")
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, transactionID)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "P1Y")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "0")
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogSubscriptionRestoredEventAndThenSubscriptionEventRestoredShouldSucceedWithStoreKit1() {
    let transactionID = "0"
    let productID = Self.ProductIdentifiers.autoRenewingSubscription1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let now = Date()
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let restoredTransaction = TestPaymentTransaction(
      identifier: transactionID,
      state: .restored,
      date: now,
      payment: payment
    )
    let newTransaction = TestPaymentTransaction(
      identifier: transactionID,
      state: .purchased,
      date: now,
      payment: payment
    )
    iapLogger.logTransaction(restoredTransaction)
    iapLogger.logTransaction(newTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .subscribeRestore)
    XCTAssertEqual(eventLogger.capturedValueToSum, 2)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: transactionID,
        eventName: .subscribeRestore
      )
    )
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: transactionID,
        eventName: .subscribe
      )
    )
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, productID.rawValue)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(
      capturedParameters[.transactionDate] as? String,
      dateFormatter.string(from: now)
    )
    XCTAssertEqual(capturedParameters[.productTitle] as? String, "")
    XCTAssertEqual(capturedParameters[.description] as? String, "")
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertEqual(capturedParameters[.transactionID] as? String, transactionID)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "P1Y")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "0")
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  // MARK: - Initiated Checkout

  func testLogInitiatedCheckoutPurchaseEvent() {
    let productID = Self.ProductIdentifiers.nonConsumableProduct1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(state: .purchasing, payment: payment)
    iapLogger.logTransaction(transaction)
    XCTAssertEqual(eventLogger.capturedEventName, .initiatedCheckout)
    XCTAssertEqual(eventLogger.capturedValueToSum, 0.99)
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, productID.rawValue)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(capturedParameters[.transactionDate] as? String, "")
    XCTAssertEqual(capturedParameters[.productTitle] as? String, "")
    XCTAssertEqual(capturedParameters[.description] as? String, "")
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertNil(capturedParameters[.transactionID])
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "inapp")
    XCTAssertNil(capturedParameters[.subscriptionPeriod])
    XCTAssertNil(capturedParameters[.isStartTrial])
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogInitiatedCheckoutSubscriptionEvent() {
    let productID = Self.ProductIdentifiers.autoRenewingSubscription1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(state: .purchasing, payment: payment)
    iapLogger.logTransaction(transaction)
    XCTAssertEqual(eventLogger.capturedEventName, .subscribeInitiatedCheckout)
    XCTAssertEqual(eventLogger.capturedValueToSum, 2.0)
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, productID.rawValue)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(capturedParameters[.transactionDate] as? String, "")
    XCTAssertEqual(capturedParameters[.productTitle] as? String, "")
    XCTAssertEqual(capturedParameters[.description] as? String, "")
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertNil(capturedParameters[.transactionID])
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "P1Y")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "0")
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogInitiatedCheckoutSubscriptionEventGKDisabled() {
    TestGateKeeperManager.gateKeepers[autoLogSubscriptionGK] = false
    let productID = Self.ProductIdentifiers.autoRenewingSubscription1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(state: .purchasing, payment: payment)
    iapLogger.logTransaction(transaction)
    XCTAssertEqual(eventLogger.capturedEventName, .initiatedCheckout)
    XCTAssertEqual(eventLogger.capturedValueToSum, 2)
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, productID.rawValue)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(capturedParameters[.transactionDate] as? String, "")
    XCTAssertEqual(capturedParameters[.productTitle] as? String, "")
    XCTAssertEqual(capturedParameters[.description] as? String, "")
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertNil(capturedParameters[.transactionID])
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "P1Y")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "0")
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  // MARK: - Failed

  func testLogFailedPurchaseEvent() {
    let productID = Self.ProductIdentifiers.nonConsumableProduct1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(state: .failed, payment: payment)
    iapLogger.logTransaction(transaction)
    XCTAssertEqual(eventLogger.capturedEventName, .purchaseFailed)
    XCTAssertEqual(eventLogger.capturedValueToSum, 0.99)
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, productID.rawValue)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(capturedParameters[.transactionDate] as? String, "")
    XCTAssertEqual(capturedParameters[.productTitle] as? String, "")
    XCTAssertEqual(capturedParameters[.description] as? String, "")
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertNil(capturedParameters[.transactionID])
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "inapp")
    XCTAssertNil(capturedParameters[.subscriptionPeriod])
    XCTAssertNil(capturedParameters[.isStartTrial])
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogFailedSubscriptionEvent() {
    let productID = Self.ProductIdentifiers.autoRenewingSubscription1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(state: .failed, payment: payment)
    iapLogger.logTransaction(transaction)
    XCTAssertEqual(eventLogger.capturedEventName, .subscribeFailed)
    XCTAssertEqual(eventLogger.capturedValueToSum, 2.0)
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, productID.rawValue)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(capturedParameters[.transactionDate] as? String, "")
    XCTAssertEqual(capturedParameters[.productTitle] as? String, "")
    XCTAssertEqual(capturedParameters[.description] as? String, "")
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertNil(capturedParameters[.transactionID])
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "P1Y")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "0")
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogFailedSubscriptionEventGKDisabled() {
    TestGateKeeperManager.gateKeepers[autoLogSubscriptionGK] = false
    let productID = Self.ProductIdentifiers.autoRenewingSubscription1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(state: .failed, payment: payment)
    iapLogger.logTransaction(transaction)
    XCTAssertEqual(eventLogger.capturedEventName, .purchaseFailed)
    XCTAssertEqual(eventLogger.capturedValueToSum, 2)
    guard let capturedParameters = eventLogger.capturedParameters else {
      XCTFail("We should have capturedParameters")
      return
    }
    XCTAssertEqual(capturedParameters[.contentID] as? String, productID.rawValue)
    XCTAssertEqual(capturedParameters[.numItems] as? Int, 1)
    XCTAssertEqual(capturedParameters[.transactionDate] as? String, "")
    XCTAssertEqual(capturedParameters[.productTitle] as? String, "")
    XCTAssertEqual(capturedParameters[.description] as? String, "")
    XCTAssertEqual(capturedParameters[.currency] as? String, "USD")
    XCTAssertNil(capturedParameters[.transactionID])
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "P1Y")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "0")
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }
}

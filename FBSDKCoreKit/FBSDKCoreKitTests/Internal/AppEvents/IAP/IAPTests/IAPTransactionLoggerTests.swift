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

@available(iOS 15.0, *)
final class IAPTransactionLoggerTests: StoreKitTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var iapLogger: IAPTransactionLogger!
  var eventLogger: TestEventLogger!
  var dateFormatter: DateFormatter!
  // swiftlint:enable implicitly_unwrapped_optional
  let autoLogSubscriptionGK = "app_events_if_auto_log_subs"

  override func setUp() async throws {
    try await super.setUp()
    dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
    IAPTransactionCache.shared.reset()
    TestGateKeeperManager.gateKeepers[autoLogSubscriptionGK] = true
    eventLogger = TestEventLogger()
    IAPTransactionLogger.configuredDependencies = .init(
      eventLogger: eventLogger
    )
    IAPEventResolver.configuredDependencies = .init(
      gateKeeperManager: TestGateKeeperManager.self
    )
    iapLogger = IAPTransactionLogger()
  }

  // MARK: - New Subscriptions

  func testLogNewSubscriptionTransactionStartTrial() async {
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.autoRenewingSubscription2.rawValue]),
      let product = products.first else {
      return
    }
    guard let result = try? await product.purchase() else {
      return
    }
    guard let iapTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return
    }
    await iapTransaction.transaction.finish()
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .startTrial)
    XCTAssertEqual(eventLogger.capturedValueToSum, 0)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: iapTransaction.transaction.originalID,
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
    XCTAssertEqual(capturedParameters[.transactionID] as? UInt64, iapTransaction.transaction.id)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "P1Y")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "1")
    XCTAssertEqual(capturedParameters[.hasFreeTrial] as? String, "1")
    XCTAssertEqual(capturedParameters[.trialPeriod] as? String, "P6M")
    XCTAssertEqual(capturedParameters[.trialPrice] as? Double, 0)
  }

  func testLogNewSubscriptionTransactionNonRenewable() async {
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.nonRenewingSubscription1.rawValue]),
      let product = products.first else {
      return
    }
    guard let result = try? await product.purchase() else {
      return
    }
    guard let iapTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return
    }
    await iapTransaction.transaction.finish()
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .subscribe)
    XCTAssertEqual(eventLogger.capturedValueToSum, 5)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: iapTransaction.transaction.originalID,
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
    XCTAssertEqual(capturedParameters[.transactionID] as? UInt64, iapTransaction.transaction.id)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "0")
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogNewSubscriptionTransactionAutoRenewable() async {
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.autoRenewingSubscription1.rawValue]),
      let product = products.first else {
      return
    }
    guard let result = try? await product.purchase() else {
      return
    }
    guard let iapTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return
    }
    await iapTransaction.transaction.finish()
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .subscribe)
    XCTAssertEqual(eventLogger.capturedValueToSum, 2)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: iapTransaction.transaction.originalID,
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
    XCTAssertEqual(capturedParameters[.transactionID] as? UInt64, iapTransaction.transaction.id)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "P1Y")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "0")
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogNewSubscriptionTransactionWithStartTrialInCache() async {
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.autoRenewingSubscription1.rawValue]),
      let product = products.first else {
      return
    }
    guard let result = try? await product.purchase() else {
      return
    }
    guard let iapTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return
    }
    await iapTransaction.transaction.finish()
    IAPTransactionCache.shared.addTransaction(
      transactionID: iapTransaction.transaction.id,
      eventName: .startTrial
    )
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .subscribe)
    XCTAssertEqual(eventLogger.capturedValueToSum, 2)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: iapTransaction.transaction.originalID,
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
    XCTAssertEqual(capturedParameters[.transactionID] as? UInt64, iapTransaction.transaction.id)
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
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.autoRenewingSubscription1.rawValue]),
      let product = products.first else {
      return
    }
    guard let result = try? await product.purchase() else {
      return
    }
    guard let iapTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return
    }
    await iapTransaction.transaction.finish()
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertNil(eventLogger.capturedEventName)
    XCTAssertNil(eventLogger.capturedValueToSum)
    XCTAssertFalse(IAPTransactionCache.shared.contains(transactionID: iapTransaction.transaction.id))
    XCTAssertNil(eventLogger.capturedParameters)
  }

  @available(iOS 17.0, *)
  func testLogNewSubscriptionTransactionExpiredSub() async {
    do {
      try await testSession.buyProduct(identifier: Self.ProductIdentifiers.autoRenewingSubscription1.rawValue)
    } catch {
      return
    }
    do {
      try testSession.expireSubscription(productIdentifier: Self.ProductIdentifiers.autoRenewingSubscription1.rawValue)
    } catch {
      return
    }
    let transactions = await Transaction.all.getValues()
    guard let transactionToLog = transactions.first?.iapTransaction else {
      return
    }
    await iapLogger.logNewTransaction(transactionToLog)
    XCTAssertNil(eventLogger.capturedEventName)
    XCTAssertNil(eventLogger.capturedValueToSum)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: transactionToLog.transaction.id,
        eventName: .subscribe
      )
    )
    XCTAssertNil(eventLogger.capturedParameters)
  }

  func testLogNewSubscriptionTransactionStartTrialWithStartTrialInCache() async {
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.autoRenewingSubscription2.rawValue]),
      let product = products.first else {
      return
    }
    guard let result = try? await product.purchase() else {
      return
    }
    guard let iapTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return
    }
    await iapTransaction.transaction.finish()
    IAPTransactionCache.shared.addTransaction(
      transactionID: iapTransaction.transaction.originalID,
      eventName: .startTrial
    )
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertNil(eventLogger.capturedEventName)
    XCTAssertNil(eventLogger.capturedValueToSum)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: iapTransaction.transaction.id,
        eventName: .startTrial
      )
    )
    XCTAssertNil(eventLogger.capturedParameters)
  }

  func testLogNewSubscriptionTransactionWithSubscribeInCache() async {
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.autoRenewingSubscription1.rawValue]),
      let product = products.first else {
      return
    }
    guard let result = try? await product.purchase() else {
      return
    }
    guard let iapTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return
    }
    await iapTransaction.transaction.finish()
    IAPTransactionCache.shared.addTransaction(
      transactionID: iapTransaction.transaction.originalID,
      eventName: .subscribe
    )
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertNil(eventLogger.capturedEventName)
    XCTAssertNil(eventLogger.capturedValueToSum)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: iapTransaction.transaction.id,
        eventName: .subscribe
      )
    )
    XCTAssertNil(eventLogger.capturedParameters)
  }

  func testLogNewSubscriptionTransactionWithRestoreInCache() async {
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.autoRenewingSubscription1.rawValue]),
      let product = products.first else {
      return
    }
    guard let result = try? await product.purchase() else {
      return
    }
    guard let iapTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return
    }
    await iapTransaction.transaction.finish()
    IAPTransactionCache.shared.addTransaction(
      transactionID: iapTransaction.transaction.originalID,
      eventName: .subscribeRestore
    )
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertNil(eventLogger.capturedEventName)
    XCTAssertNil(eventLogger.capturedValueToSum)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: iapTransaction.transaction.id,
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
        transactionID: renewalTransaction.transaction.originalID,
        eventName: .subscribe
      )
    )
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: renewalTransaction.transaction.id,
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
    XCTAssertEqual(capturedParameters[.transactionID] as? UInt64, originalTransaction.transaction.id)
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
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.consumableProduct1.rawValue]),
      let product = products.first else {
      return
    }
    guard let result = try? await product.purchase() else {
      return
    }
    guard let iapTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return
    }
    await iapTransaction.transaction.finish()
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .purchased)
    XCTAssertEqual(eventLogger.capturedValueToSum, 10)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: iapTransaction.transaction.originalID,
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
    XCTAssertEqual(capturedParameters[.transactionID] as? UInt64, iapTransaction.transaction.id)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "inapp")
    XCTAssertNil(capturedParameters[.subscriptionPeriod])
    XCTAssertNil(capturedParameters[.isStartTrial])
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogNewPurchaseTransactionNonConsumable() async {
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.nonConsumableProduct1.rawValue]),
      let product = products.first else {
      return
    }
    guard let result = try? await product.purchase() else {
      return
    }
    guard let iapTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return
    }
    await iapTransaction.transaction.finish()
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .purchased)
    XCTAssertEqual(eventLogger.capturedValueToSum, 0.99)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: iapTransaction.transaction.originalID,
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
    XCTAssertEqual(capturedParameters[.transactionID] as? UInt64, iapTransaction.transaction.id)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "inapp")
    XCTAssertNil(capturedParameters[.subscriptionPeriod])
    XCTAssertNil(capturedParameters[.isStartTrial])
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogNewPurchaseTransactionWithPurchaseInCache() async {
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.nonConsumableProduct1.rawValue]),
      let product = products.first else {
      return
    }
    guard let result = try? await product.purchase() else {
      return
    }
    guard let iapTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return
    }
    await iapTransaction.transaction.finish()
    IAPTransactionCache.shared.addTransaction(
      transactionID: iapTransaction.transaction.originalID,
      eventName: .purchased
    )
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertNil(eventLogger.capturedEventName)
    XCTAssertNil(eventLogger.capturedValueToSum)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: iapTransaction.transaction.id,
        eventName: .purchased
      )
    )
    XCTAssertNil(eventLogger.capturedParameters)
  }

  // MARK: - Restored Subscriptions

  func testLogRestoredSubscriptionTransactionAutoRenewableStartTrial() async {
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.autoRenewingSubscription2.rawValue]),
      let product = products.first else {
      return
    }
    guard let result = try? await product.purchase() else {
      return
    }
    guard let iapTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return
    }
    await iapTransaction.transaction.finish()
    await iapLogger.logRestoredTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .subscribeRestore)
    XCTAssertEqual(eventLogger.capturedValueToSum, 0)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: iapTransaction.transaction.originalID,
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
    XCTAssertEqual(capturedParameters[.transactionID] as? UInt64, iapTransaction.transaction.id)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "P1Y")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "1")
    XCTAssertEqual(capturedParameters[.hasFreeTrial] as? String, "1")
    XCTAssertEqual(capturedParameters[.trialPeriod] as? String, "P6M")
    XCTAssertEqual(capturedParameters[.trialPrice] as? Double, 0)
  }

  func testLogRestoredSubscriptionTransactionNonRenewable() async {
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.nonRenewingSubscription1.rawValue]),
      let product = products.first else {
      return
    }
    guard let result = try? await product.purchase() else {
      return
    }
    guard let iapTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return
    }
    await iapTransaction.transaction.finish()
    await iapLogger.logRestoredTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .subscribeRestore)
    XCTAssertEqual(eventLogger.capturedValueToSum, 5)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: iapTransaction.transaction.originalID,
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
    XCTAssertEqual(capturedParameters[.transactionID] as? UInt64, iapTransaction.transaction.id)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "0")
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogRestoredSubscriptionTransactionAutoRenewable() async {
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.autoRenewingSubscription1.rawValue]),
      let product = products.first else {
      return
    }
    guard let result = try? await product.purchase() else {
      return
    }
    guard let iapTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return
    }
    await iapTransaction.transaction.finish()
    await iapLogger.logRestoredTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .subscribeRestore)
    XCTAssertEqual(eventLogger.capturedValueToSum, 2)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: iapTransaction.transaction.originalID,
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
    XCTAssertEqual(capturedParameters[.transactionID] as? UInt64, iapTransaction.transaction.id)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "P1Y")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "0")
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogRestoredSubscriptionTransactionWithRestoredInCache() async {
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.autoRenewingSubscription1.rawValue]),
      let product = products.first else {
      return
    }
    guard let result = try? await product.purchase() else {
      return
    }
    guard let iapTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return
    }
    await iapTransaction.transaction.finish()
    IAPTransactionCache.shared.addTransaction(
      transactionID: iapTransaction.transaction.originalID,
      eventName: .subscribeRestore
    )
    await iapLogger.logRestoredTransaction(iapTransaction)
    XCTAssertNil(eventLogger.capturedEventName)
    XCTAssertNil(eventLogger.capturedValueToSum)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: iapTransaction.transaction.id,
        eventName: .subscribeRestore
      )
    )
    XCTAssertNil(eventLogger.capturedParameters)
  }

  func testLogRestoredSubscriptionTransactionGKDisabled() async {
    TestGateKeeperManager.gateKeepers[autoLogSubscriptionGK] = false
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.autoRenewingSubscription1.rawValue]),
      let product = products.first else {
      return
    }
    guard let result = try? await product.purchase() else {
      return
    }
    guard let iapTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return
    }
    await iapTransaction.transaction.finish()
    await iapLogger.logRestoredTransaction(iapTransaction)
    XCTAssertNil(eventLogger.capturedEventName)
    XCTAssertNil(eventLogger.capturedValueToSum)
    XCTAssertFalse(IAPTransactionCache.shared.contains(transactionID: iapTransaction.transaction.id))
    XCTAssertNil(eventLogger.capturedParameters)
  }

  // MARK: - Restored Purchases

  func testLogRestoredPurchaseTransaction_1() async {
    // Purchase - consumable
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.consumableProduct1.rawValue]),
      let product = products.first else {
      return
    }
    guard let result = try? await product.purchase() else {
      return
    }
    guard let iapTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return
    }
    await iapTransaction.transaction.finish()
    await iapLogger.logRestoredTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .purchaseRestored)
    XCTAssertEqual(eventLogger.capturedValueToSum, 10)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: iapTransaction.transaction.originalID,
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
    XCTAssertEqual(capturedParameters[.transactionID] as? UInt64, iapTransaction.transaction.id)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "inapp")
    XCTAssertNil(capturedParameters[.subscriptionPeriod])
    XCTAssertNil(capturedParameters[.isStartTrial])
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogRestoredPurchaseTransaction_2() async {
    // Purchase - non consumable
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.nonConsumableProduct1.rawValue]),
      let product = products.first else {
      return
    }
    guard let result = try? await product.purchase() else {
      return
    }
    guard let iapTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return
    }
    await iapTransaction.transaction.finish()
    await iapLogger.logRestoredTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .purchaseRestored)
    XCTAssertEqual(eventLogger.capturedValueToSum, 0.99)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: iapTransaction.transaction.originalID,
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
    XCTAssertEqual(capturedParameters[.transactionID] as? UInt64, iapTransaction.transaction.id)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "inapp")
    XCTAssertNil(capturedParameters[.subscriptionPeriod])
    XCTAssertNil(capturedParameters[.isStartTrial])
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogRestoredPurchaseTransaction_3() async {
    // Purchase - cache contains restored
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.nonConsumableProduct1.rawValue]),
      let product = products.first else {
      return
    }
    guard let result = try? await product.purchase() else {
      return
    }
    guard let iapTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return
    }
    await iapTransaction.transaction.finish()
    IAPTransactionCache.shared.addTransaction(
      transactionID: iapTransaction.transaction.originalID,
      eventName: .purchaseRestored
    )
    await iapLogger.logRestoredTransaction(iapTransaction)
    XCTAssertNil(eventLogger.capturedEventName)
    XCTAssertNil(eventLogger.capturedValueToSum)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: iapTransaction.transaction.id,
        eventName: .purchaseRestored
      )
    )
    XCTAssertNil(eventLogger.capturedParameters)
  }

  // MARK: - Duplicates

  func testLogDuplicatePurchaseEvent() async {
    // New Purchase -> New Purchase
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.nonConsumableProduct1.rawValue]),
      let product = products.first else {
      return
    }
    guard let result = try? await product.purchase() else {
      return
    }
    guard let iapTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return
    }
    await iapTransaction.transaction.finish()
    await iapLogger.logNewTransaction(iapTransaction)
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .purchased)
    XCTAssertEqual(eventLogger.capturedValueToSum, 0.99)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: iapTransaction.transaction.id,
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
    XCTAssertEqual(capturedParameters[.transactionID] as? UInt64, iapTransaction.transaction.id)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "inapp")
    XCTAssertNil(capturedParameters[.subscriptionPeriod])
    XCTAssertNil(capturedParameters[.isStartTrial])
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogDuplicatePurchaseRestoredEvent() async {
    // Purchase Restored -> New Purchase
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.nonConsumableProduct1.rawValue]),
      let product = products.first else {
      return
    }
    guard let result = try? await product.purchase() else {
      return
    }
    guard let iapTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return
    }
    await iapTransaction.transaction.finish()
    await iapLogger.logRestoredTransaction(iapTransaction)
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .purchaseRestored)
    XCTAssertEqual(eventLogger.capturedValueToSum, 0.99)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: iapTransaction.transaction.originalID,
        eventName: .purchaseRestored
      )
    )
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: iapTransaction.transaction.id,
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
    XCTAssertEqual(capturedParameters[.transactionID] as? UInt64, iapTransaction.transaction.id)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "inapp")
    XCTAssertNil(capturedParameters[.subscriptionPeriod])
    XCTAssertNil(capturedParameters[.isStartTrial])
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogDuplicateSubscriptionEvent() async {
    // New Subscription -> New Subscription
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.autoRenewingSubscription1.rawValue]),
      let product = products.first else {
      return
    }
    guard let result = try? await product.purchase() else {
      return
    }
    guard let iapTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return
    }
    await iapTransaction.transaction.finish()
    await iapLogger.logNewTransaction(iapTransaction)
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .subscribe)
    XCTAssertEqual(eventLogger.capturedValueToSum, 2)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: iapTransaction.transaction.id,
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
    XCTAssertEqual(capturedParameters[.transactionID] as? UInt64, iapTransaction.transaction.id)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "P1Y")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "0")
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }

  func testLogDuplicateSubscriptionRestoredEvent() async {
    // Subscription Restored -> New Subscription
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.autoRenewingSubscription1.rawValue]),
      let product = products.first else {
      return
    }
    guard let result = try? await product.purchase() else {
      return
    }
    guard let iapTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return
    }
    await iapTransaction.transaction.finish()
    await iapLogger.logRestoredTransaction(iapTransaction)
    await iapLogger.logNewTransaction(iapTransaction)
    XCTAssertEqual(eventLogger.capturedEventName, .subscribeRestore)
    XCTAssertEqual(eventLogger.capturedValueToSum, 2)
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: iapTransaction.transaction.originalID,
        eventName: .subscribeRestore
      )
    )
    XCTAssertTrue(
      IAPTransactionCache.shared.contains(
        transactionID: iapTransaction.transaction.id,
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
    XCTAssertEqual(capturedParameters[.transactionID] as? UInt64, iapTransaction.transaction.id)
    XCTAssertEqual(capturedParameters[.implicitlyLoggedPurchase] as? String, "1")
    XCTAssertEqual(capturedParameters[.inAppPurchaseType] as? String, "subs")
    XCTAssertEqual(capturedParameters[.subscriptionPeriod] as? String, "P1Y")
    XCTAssertEqual(capturedParameters[.isStartTrial] as? String, "0")
    XCTAssertNil(capturedParameters[.hasFreeTrial])
    XCTAssertNil(capturedParameters[.trialPeriod])
    XCTAssertNil(capturedParameters[.trialPrice])
  }
}

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
final class IAPEventResolverTests: StoreKitTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  private var eventResolver: IAPEventResolver!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() async throws {
    try await super.setUp()
    TestGateKeeperManager.gateKeepers["app_events_if_auto_log_subs"] = true
    IAPEventResolver.configuredDependencies = .init(
      gateKeeperManager: TestGateKeeperManager.self
    )
    eventResolver = IAPEventResolver()
  }

  override func tearDown() {
    eventResolver = nil
    super.tearDown()
  }

  func testResolveNewNonConsumablePurchaseEvent() async {
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
    let expectedEvent = IAPEvent(
      eventName: .purchased,
      productID: Self.ProductIdentifiers.nonConsumableProduct1.rawValue,
      productTitle: product.displayName,
      productDescription: product.description,
      amount: 0.99,
      quantity: 1,
      currency: "USD",
      transactionID: iapTransaction.transaction.id,
      originalTransactionID: iapTransaction.transaction.originalID,
      transactionDate: iapTransaction.transaction.purchaseDate,
      originalTransactionDate: iapTransaction.transaction.originalPurchaseDate,
      isVerified: true,
      subscriptionPeriod: nil,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil
    )
    let event = await eventResolver.resolveNewEventFor(iapTransaction: iapTransaction)
    XCTAssertEqual(event, expectedEvent)
  }

  func testResolveNewConsumablePurchaseEvent() async {
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
    let expectedEvent = IAPEvent(
      eventName: .purchased,
      productID: Self.ProductIdentifiers.consumableProduct1.rawValue,
      productTitle: product.displayName,
      productDescription: product.description,
      amount: 10,
      quantity: 1,
      currency: "USD",
      transactionID: iapTransaction.transaction.id,
      originalTransactionID: iapTransaction.transaction.originalID,
      transactionDate: iapTransaction.transaction.purchaseDate,
      originalTransactionDate: iapTransaction.transaction.originalPurchaseDate,
      isVerified: true,
      subscriptionPeriod: nil,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil
    )
    let event = await eventResolver.resolveNewEventFor(iapTransaction: iapTransaction)
    XCTAssertEqual(event, expectedEvent)
  }

  func testResolveNewNonRenewingSubscriptionEvent() async {
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
    let expectedEvent = IAPEvent(
      eventName: .subscribe,
      productID: Self.ProductIdentifiers.nonRenewingSubscription1.rawValue,
      productTitle: product.displayName,
      productDescription: product.description,
      amount: 5,
      quantity: 1,
      currency: "USD",
      transactionID: iapTransaction.transaction.id,
      originalTransactionID: iapTransaction.transaction.originalID,
      transactionDate: iapTransaction.transaction.purchaseDate,
      originalTransactionDate: iapTransaction.transaction.originalPurchaseDate,
      isVerified: true,
      subscriptionPeriod: nil,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil
    )
    let event = await eventResolver.resolveNewEventFor(iapTransaction: iapTransaction)
    XCTAssertEqual(event, expectedEvent)
  }

  func testResolveNewAutoRenewingSubscriptionEvent() async {
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
    let subscriptionPeriod = IAPSubscriptionPeriod(unit: .year, numUnits: 1)
    let expectedEvent = IAPEvent(
      eventName: .subscribe,
      productID: Self.ProductIdentifiers.autoRenewingSubscription1.rawValue,
      productTitle: product.displayName,
      productDescription: product.description,
      amount: 2,
      quantity: 1,
      currency: "USD",
      transactionID: iapTransaction.transaction.id,
      originalTransactionID: iapTransaction.transaction.originalID,
      transactionDate: iapTransaction.transaction.purchaseDate,
      originalTransactionDate: iapTransaction.transaction.originalPurchaseDate,
      isVerified: true,
      subscriptionPeriod: subscriptionPeriod,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil
    )
    let event = await eventResolver.resolveNewEventFor(iapTransaction: iapTransaction)
    XCTAssertEqual(event, expectedEvent)
  }

  func testResolveNewStartTrialSubscriptionEvent() async {
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
    let subscriptionPeriod = IAPSubscriptionPeriod(unit: .year, numUnits: 1)
    let introOfferSubscriptionPeriod = IAPSubscriptionPeriod(unit: .month, numUnits: 6)
    let expectedEvent = IAPEvent(
      eventName: .startTrial,
      productID: Self.ProductIdentifiers.autoRenewingSubscription2.rawValue,
      productTitle: product.displayName,
      productDescription: product.description,
      amount: 0,
      quantity: 1,
      currency: "USD",
      transactionID: iapTransaction.transaction.id,
      originalTransactionID: iapTransaction.transaction.originalID,
      transactionDate: iapTransaction.transaction.purchaseDate,
      originalTransactionDate: iapTransaction.transaction.originalPurchaseDate,
      isVerified: true,
      subscriptionPeriod: subscriptionPeriod,
      isStartTrial: true,
      hasIntroductoryOffer: true,
      hasFreeTrial: true,
      introductoryOfferSubscriptionPeriod: introOfferSubscriptionPeriod,
      introductoryOfferPrice: 0.0
    )
    let event = await eventResolver.resolveNewEventFor(iapTransaction: iapTransaction)
    XCTAssertEqual(event, expectedEvent)
  }

  func testResolveNewAutoSubscriptionEventGKDisabled() async {
    TestGateKeeperManager.gateKeepers["app_events_if_auto_log_subs"] = false
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
    let event = await eventResolver.resolveNewEventFor(iapTransaction: iapTransaction)
    XCTAssertNil(event)
  }

  func testResolveRestoredPurchaseEvent() async {
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
    let expectedEvent = IAPEvent(
      eventName: .purchaseRestored,
      productID: Self.ProductIdentifiers.nonConsumableProduct1.rawValue,
      productTitle: product.displayName,
      productDescription: product.description,
      amount: 0.99,
      quantity: 1,
      currency: "USD",
      transactionID: iapTransaction.transaction.id,
      originalTransactionID: iapTransaction.transaction.originalID,
      transactionDate: iapTransaction.transaction.purchaseDate,
      originalTransactionDate: iapTransaction.transaction.originalPurchaseDate,
      isVerified: true,
      subscriptionPeriod: nil,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil
    )
    let event = await eventResolver.resolveRestoredEventFor(iapTransaction: iapTransaction)
    XCTAssertEqual(event, expectedEvent)
  }

  func testResolveRestoredAutoRenewingSubscriptionEvent() async {
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
    let subscriptionPeriod = IAPSubscriptionPeriod(unit: .year, numUnits: 1)
    let expectedEvent = IAPEvent(
      eventName: .subscribeRestore,
      productID: Self.ProductIdentifiers.autoRenewingSubscription1.rawValue,
      productTitle: product.displayName,
      productDescription: product.description,
      amount: 2,
      quantity: 1,
      currency: "USD",
      transactionID: iapTransaction.transaction.id,
      originalTransactionID: iapTransaction.transaction.originalID,
      transactionDate: iapTransaction.transaction.purchaseDate,
      originalTransactionDate: iapTransaction.transaction.originalPurchaseDate,
      isVerified: true,
      subscriptionPeriod: subscriptionPeriod,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil
    )
    let event = await eventResolver.resolveRestoredEventFor(iapTransaction: iapTransaction)
    XCTAssertEqual(event, expectedEvent)
  }

  func testResolveRestoredStartTrialSubscriptionEvent() async {
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
    let subscriptionPeriod = IAPSubscriptionPeriod(unit: .year, numUnits: 1)
    let introOfferSubscriptionPeriod = IAPSubscriptionPeriod(unit: .month, numUnits: 6)
    let expectedEvent = IAPEvent(
      eventName: .subscribeRestore,
      productID: Self.ProductIdentifiers.autoRenewingSubscription2.rawValue,
      productTitle: product.displayName,
      productDescription: product.description,
      amount: 0,
      quantity: 1,
      currency: "USD",
      transactionID: iapTransaction.transaction.id,
      originalTransactionID: iapTransaction.transaction.originalID,
      transactionDate: iapTransaction.transaction.purchaseDate,
      originalTransactionDate: iapTransaction.transaction.originalPurchaseDate,
      isVerified: true,
      subscriptionPeriod: subscriptionPeriod,
      isStartTrial: true,
      hasIntroductoryOffer: true,
      hasFreeTrial: true,
      introductoryOfferSubscriptionPeriod: introOfferSubscriptionPeriod,
      introductoryOfferPrice: 0.0
    )
    let event = await eventResolver.resolveRestoredEventFor(iapTransaction: iapTransaction)
    XCTAssertEqual(event, expectedEvent)
  }

  func testResolveRestoredAutoSubscriptionEventGKDisabled() async {
    TestGateKeeperManager.gateKeepers["app_events_if_auto_log_subs"] = false
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
    let event = await eventResolver.resolveRestoredEventFor(iapTransaction: iapTransaction)
    XCTAssertNil(event)
  }
}

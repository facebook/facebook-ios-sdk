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

final class IAPEventResolverTests: StoreKitTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  private var eventResolver: IAPEventResolver!
  private var delegate: TestIAPEventResolverDelegate!
  private var iapSKProductRequestFactory: TestIAPSKProductsRequestFactory!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() async throws {
    try await super.setUp()
    TestGateKeeperManager.gateKeepers["app_events_if_auto_log_subs"] = true
    delegate = TestIAPEventResolverDelegate()
    iapSKProductRequestFactory = TestIAPSKProductsRequestFactory()
    IAPEventResolver.configuredDependencies = .init(
      gateKeeperManager: TestGateKeeperManager.self,
      iapSKProductRequestFactory: iapSKProductRequestFactory
    )
    eventResolver = IAPEventResolver()
    eventResolver.delegate = delegate
  }

  override func tearDown() {
    delegate.reset()
    delegate = nil
    eventResolver = nil
    super.tearDown()
  }
}

// MARK: - Store Kit 2

@available(iOS 15.0, *)
extension IAPEventResolverTests {
  func testResolveNewNonConsumablePurchaseEventWithStoreKit2() async {
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
      transactionID: String(iapTransaction.transaction.id),
      originalTransactionID: String(iapTransaction.transaction.originalID),
      transactionDate: iapTransaction.transaction.purchaseDate,
      originalTransactionDate: iapTransaction.transaction.originalPurchaseDate,
      isVerified: true,
      isSubscription: false,
      subscriptionPeriod: nil,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil,
      storeKitVersion: .version2
    )
    let event = await eventResolver.resolveNewEventFor(iapTransaction: iapTransaction)
    XCTAssertEqual(event, expectedEvent)
  }

  func testResolveNewConsumablePurchaseEventWithStoreKit2() async {
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
      transactionID: String(iapTransaction.transaction.id),
      originalTransactionID: String(iapTransaction.transaction.originalID),
      transactionDate: iapTransaction.transaction.purchaseDate,
      originalTransactionDate: iapTransaction.transaction.originalPurchaseDate,
      isVerified: true,
      isSubscription: false,
      subscriptionPeriod: nil,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil,
      storeKitVersion: .version2
    )
    let event = await eventResolver.resolveNewEventFor(iapTransaction: iapTransaction)
    XCTAssertEqual(event, expectedEvent)
  }

  func testResolveNewNonRenewingSubscriptionEventWithStoreKit2() async {
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
      eventName: .purchased,
      productID: Self.ProductIdentifiers.nonRenewingSubscription1.rawValue,
      productTitle: product.displayName,
      productDescription: product.description,
      amount: 5,
      quantity: 1,
      currency: "USD",
      transactionID: String(iapTransaction.transaction.id),
      originalTransactionID: String(iapTransaction.transaction.originalID),
      transactionDate: iapTransaction.transaction.purchaseDate,
      originalTransactionDate: iapTransaction.transaction.originalPurchaseDate,
      isVerified: true,
      isSubscription: false,
      subscriptionPeriod: nil,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil,
      storeKitVersion: .version2
    )
    let event = await eventResolver.resolveNewEventFor(iapTransaction: iapTransaction)
    XCTAssertEqual(event, expectedEvent)
  }

  func testResolveNewAutoRenewingSubscriptionEventWithStoreKit2() async {
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
      transactionID: String(iapTransaction.transaction.id),
      originalTransactionID: String(iapTransaction.transaction.originalID),
      transactionDate: iapTransaction.transaction.purchaseDate,
      originalTransactionDate: iapTransaction.transaction.originalPurchaseDate,
      isVerified: true,
      isSubscription: true,
      subscriptionPeriod: subscriptionPeriod,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil,
      storeKitVersion: .version2
    )
    let event = await eventResolver.resolveNewEventFor(iapTransaction: iapTransaction)
    XCTAssertEqual(event, expectedEvent)
  }

  func testResolveNewStartTrialSubscriptionEventWithStoreKit2() async {
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
      transactionID: String(iapTransaction.transaction.id),
      originalTransactionID: String(iapTransaction.transaction.originalID),
      transactionDate: iapTransaction.transaction.purchaseDate,
      originalTransactionDate: iapTransaction.transaction.originalPurchaseDate,
      isVerified: true,
      isSubscription: true,
      subscriptionPeriod: subscriptionPeriod,
      isStartTrial: true,
      hasIntroductoryOffer: true,
      hasFreeTrial: true,
      introductoryOfferSubscriptionPeriod: introOfferSubscriptionPeriod,
      introductoryOfferPrice: 0.0,
      storeKitVersion: .version2
    )
    let event = await eventResolver.resolveNewEventFor(iapTransaction: iapTransaction)
    XCTAssertEqual(event, expectedEvent)
  }

  func testResolveNewAutoSubscriptionEventGKDisabledWithStoreKit2() async {
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
    let subscriptionPeriod = IAPSubscriptionPeriod(unit: .year, numUnits: 1)
    let expectedEvent = IAPEvent(
      eventName: .purchased,
      productID: Self.ProductIdentifiers.autoRenewingSubscription1.rawValue,
      productTitle: product.displayName,
      productDescription: product.description,
      amount: 2,
      quantity: 1,
      currency: "USD",
      transactionID: String(iapTransaction.transaction.id),
      originalTransactionID: String(iapTransaction.transaction.originalID),
      transactionDate: iapTransaction.transaction.purchaseDate,
      originalTransactionDate: iapTransaction.transaction.originalPurchaseDate,
      isVerified: true,
      isSubscription: true,
      subscriptionPeriod: subscriptionPeriod,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil,
      storeKitVersion: .version2
    )
    let event = await eventResolver.resolveNewEventFor(iapTransaction: iapTransaction)
    XCTAssertEqual(event, expectedEvent)
  }

  func testResolveRestoredPurchaseEventWithStoreKit2() async {
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
      transactionID: String(iapTransaction.transaction.id),
      originalTransactionID: String(iapTransaction.transaction.originalID),
      transactionDate: iapTransaction.transaction.purchaseDate,
      originalTransactionDate: iapTransaction.transaction.originalPurchaseDate,
      isVerified: true,
      isSubscription: false,
      subscriptionPeriod: nil,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil,
      storeKitVersion: .version2
    )
    let event = await eventResolver.resolveRestoredEventFor(iapTransaction: iapTransaction)
    XCTAssertEqual(event, expectedEvent)
  }

  func testResolveRestoredAutoRenewingSubscriptionEventWithStoreKit2() async {
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
      transactionID: String(iapTransaction.transaction.id),
      originalTransactionID: String(iapTransaction.transaction.originalID),
      transactionDate: iapTransaction.transaction.purchaseDate,
      originalTransactionDate: iapTransaction.transaction.originalPurchaseDate,
      isVerified: true,
      isSubscription: true,
      subscriptionPeriod: subscriptionPeriod,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil,
      storeKitVersion: .version2
    )
    let event = await eventResolver.resolveRestoredEventFor(iapTransaction: iapTransaction)
    XCTAssertEqual(event, expectedEvent)
  }

  func testResolveRestoredStartTrialSubscriptionEventWithStoreKit2() async {
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
      transactionID: String(iapTransaction.transaction.id),
      originalTransactionID: String(iapTransaction.transaction.originalID),
      transactionDate: iapTransaction.transaction.purchaseDate,
      originalTransactionDate: iapTransaction.transaction.originalPurchaseDate,
      isVerified: true,
      isSubscription: true,
      subscriptionPeriod: subscriptionPeriod,
      isStartTrial: true,
      hasIntroductoryOffer: true,
      hasFreeTrial: true,
      introductoryOfferSubscriptionPeriod: introOfferSubscriptionPeriod,
      introductoryOfferPrice: 0.0,
      storeKitVersion: .version2
    )
    let event = await eventResolver.resolveRestoredEventFor(iapTransaction: iapTransaction)
    XCTAssertEqual(event, expectedEvent)
  }

  func testResolveRestoredAutoSubscriptionEventGKDisabledWithStoreKit2() async {
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
    let subscriptionPeriod = IAPSubscriptionPeriod(unit: .year, numUnits: 1)
    let expectedEvent = IAPEvent(
      eventName: .purchaseRestored,
      productID: Self.ProductIdentifiers.autoRenewingSubscription1.rawValue,
      productTitle: product.displayName,
      productDescription: product.description,
      amount: 2,
      quantity: 1,
      currency: "USD",
      transactionID: String(iapTransaction.transaction.id),
      originalTransactionID: String(iapTransaction.transaction.originalID),
      transactionDate: iapTransaction.transaction.purchaseDate,
      originalTransactionDate: iapTransaction.transaction.originalPurchaseDate,
      isVerified: true,
      isSubscription: true,
      subscriptionPeriod: subscriptionPeriod,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil,
      storeKitVersion: .version2
    )
    let event = await eventResolver.resolveRestoredEventFor(iapTransaction: iapTransaction)
    XCTAssertEqual(event, expectedEvent)
  }
}

// MARK: - Store Kit 1

@available(iOS 12.2, *)
extension IAPEventResolverTests {
  func testResolveNewNonConsumablePurchaseEventWithStoreKit1() {
    let productID = Self.ProductIdentifiers.nonConsumableProduct1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let now = Date()
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(identifier: "0", state: .purchased, date: now, payment: payment)
    eventResolver.resolveEventFor(transaction: transaction)
    let expectedEvent = IAPEvent(
      eventName: .purchased,
      productID: productID.rawValue,
      productTitle: "",
      productDescription: "",
      amount: 0.99,
      quantity: 1,
      currency: "USD",
      transactionID: "0",
      originalTransactionID: "0",
      transactionDate: now,
      originalTransactionDate: now,
      isVerified: false,
      isSubscription: false,
      subscriptionPeriod: nil,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil,
      storeKitVersion: .version1
    )
    let predicate = NSPredicate { _, _ -> Bool in
      self.delegate.capturedNewEvent == expectedEvent
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    wait(for: [expectation], timeout: 20.0)
  }

  func testResolveNewConsumablePurchaseEventWithStoreKit1() {
    let productID = Self.ProductIdentifiers.consumableProduct1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let now = Date()
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 2)
    let transaction = TestPaymentTransaction(identifier: "0", state: .purchased, date: now, payment: payment)
    eventResolver.resolveEventFor(transaction: transaction)
    let expectedEvent = IAPEvent(
      eventName: .purchased,
      productID: productID.rawValue,
      productTitle: "",
      productDescription: "",
      amount: 20,
      quantity: 2,
      currency: "USD",
      transactionID: "0",
      originalTransactionID: "0",
      transactionDate: now,
      originalTransactionDate: now,
      isVerified: false,
      isSubscription: false,
      subscriptionPeriod: nil,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil,
      storeKitVersion: .version1
    )
    let predicate = NSPredicate { _, _ -> Bool in
      self.delegate.capturedNewEvent == expectedEvent
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    wait(for: [expectation], timeout: 20.0)
  }

  func testResolveNewNonRenewingSubscriptionEventWithStoreKit1() {
    let productID = Self.ProductIdentifiers.nonRenewingSubscription1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let now = Date()
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(identifier: "0", state: .purchased, date: now, payment: payment)
    eventResolver.resolveEventFor(transaction: transaction)
    let expectedEvent = IAPEvent(
      eventName: .purchased,
      productID: productID.rawValue,
      productTitle: "",
      productDescription: "",
      amount: 5,
      quantity: 1,
      currency: "USD",
      transactionID: "0",
      originalTransactionID: "0",
      transactionDate: now,
      originalTransactionDate: now,
      isVerified: false,
      isSubscription: false,
      subscriptionPeriod: nil,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil,
      storeKitVersion: .version1
    )
    let predicate = NSPredicate { _, _ -> Bool in
      self.delegate.capturedNewEvent == expectedEvent
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    wait(for: [expectation], timeout: 20.0)
  }

  func testResolveNewAutoRenewingSubscriptionEventWithStoreKit1() {
    let productID = Self.ProductIdentifiers.autoRenewingSubscription1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let now = Date()
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(identifier: "0", state: .purchased, date: now, payment: payment)
    eventResolver.resolveEventFor(transaction: transaction)
    let subscriptionPeriod = IAPSubscriptionPeriod(unit: .year, numUnits: 1)
    let expectedEvent = IAPEvent(
      eventName: .subscribe,
      productID: productID.rawValue,
      productTitle: "",
      productDescription: "",
      amount: 2,
      quantity: 1,
      currency: "USD",
      transactionID: "0",
      originalTransactionID: "0",
      transactionDate: now,
      originalTransactionDate: now,
      isVerified: false,
      isSubscription: true,
      subscriptionPeriod: subscriptionPeriod,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil,
      storeKitVersion: .version1
    )
    let predicate = NSPredicate { _, _ -> Bool in
      self.delegate.capturedNewEvent == expectedEvent
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    wait(for: [expectation], timeout: 20.0)
  }

  func testResolveNewStartTrialSubscriptionEventWithStoreKit1() {
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
    let transaction = TestPaymentTransaction(identifier: "0", state: .purchased, date: now, payment: payment)
    eventResolver.resolveEventFor(transaction: transaction)
    let subscriptionPeriod = IAPSubscriptionPeriod(unit: .year, numUnits: 1)
    let introOfferSubscriptionPeriod = IAPSubscriptionPeriod(unit: .month, numUnits: 6)
    let expectedEvent = IAPEvent(
      eventName: .startTrial,
      productID: productID.rawValue,
      productTitle: "",
      productDescription: "",
      amount: 0,
      quantity: 1,
      currency: "USD",
      transactionID: "0",
      originalTransactionID: "0",
      transactionDate: now,
      originalTransactionDate: now,
      isVerified: false,
      isSubscription: true,
      subscriptionPeriod: subscriptionPeriod,
      isStartTrial: true,
      hasIntroductoryOffer: true,
      hasFreeTrial: true,
      introductoryOfferSubscriptionPeriod: introOfferSubscriptionPeriod,
      introductoryOfferPrice: 0.0,
      storeKitVersion: .version1
    )
    let predicate = NSPredicate { _, _ -> Bool in
      self.delegate.capturedNewEvent == expectedEvent
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    wait(for: [expectation], timeout: 20.0)
  }

  func testResolveNewAutoSubscriptionEventGKDisabledWithStoreKit1() {
    let productID = Self.ProductIdentifiers.autoRenewingSubscription1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    TestGateKeeperManager.gateKeepers["app_events_if_auto_log_subs"] = false
    let now = Date()
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(identifier: "0", state: .purchased, date: now, payment: payment)
    let subscriptionPeriod = IAPSubscriptionPeriod(unit: .year, numUnits: 1)
    let expectedEvent = IAPEvent(
      eventName: .purchased,
      productID: productID.rawValue,
      productTitle: "",
      productDescription: "",
      amount: 2,
      quantity: 1,
      currency: "USD",
      transactionID: "0",
      originalTransactionID: "0",
      transactionDate: now,
      originalTransactionDate: now,
      isVerified: false,
      isSubscription: true,
      subscriptionPeriod: subscriptionPeriod,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil,
      storeKitVersion: .version1
    )
    eventResolver.resolveEventFor(transaction: transaction)
    let predicate = NSPredicate { _, _ -> Bool in
      self.delegate.capturedNewEvent == expectedEvent
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    wait(for: [expectation], timeout: 20.0)
  }

  func testResolveRestoredPurchaseEventWithStoreKit1() {
    let productID = Self.ProductIdentifiers.nonConsumableProduct1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let now = Date()
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let originalTransaction = TestPaymentTransaction(identifier: "0", state: .purchased, date: now, payment: payment)
    let transaction = TestPaymentTransaction(
      identifier: "1",
      state: .restored,
      date: now,
      payment: payment,
      originalTransaction: originalTransaction
    )
    eventResolver.resolveEventFor(transaction: transaction)
    let expectedEvent = IAPEvent(
      eventName: .purchaseRestored,
      productID: productID.rawValue,
      productTitle: "",
      productDescription: "",
      amount: 0.99,
      quantity: 1,
      currency: "USD",
      transactionID: "1",
      originalTransactionID: "0",
      transactionDate: now,
      originalTransactionDate: now,
      isVerified: false,
      isSubscription: false,
      subscriptionPeriod: nil,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil,
      storeKitVersion: .version1
    )
    let predicate = NSPredicate { _, _ -> Bool in
      self.delegate.capturedRestoredEvent == expectedEvent && self.delegate.capturedNewEvent == nil
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    wait(for: [expectation], timeout: 20.0)
  }

  func testResolveRestoredAutoRenewingSubscriptionEventWithStoreKit1() {
    let productID = Self.ProductIdentifiers.autoRenewingSubscription1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let now = Date()
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let originalTransaction = TestPaymentTransaction(identifier: "0", state: .purchased, date: now, payment: payment)
    let transaction = TestPaymentTransaction(
      identifier: "1",
      state: .restored,
      date: now,
      payment: payment,
      originalTransaction: originalTransaction
    )
    eventResolver.resolveEventFor(transaction: transaction)
    let subscriptionPeriod = IAPSubscriptionPeriod(unit: .year, numUnits: 1)
    let expectedEvent = IAPEvent(
      eventName: .subscribeRestore,
      productID: productID.rawValue,
      productTitle: "",
      productDescription: "",
      amount: 2,
      quantity: 1,
      currency: "USD",
      transactionID: "1",
      originalTransactionID: "0",
      transactionDate: now,
      originalTransactionDate: now,
      isVerified: false,
      isSubscription: true,
      subscriptionPeriod: subscriptionPeriod,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil,
      storeKitVersion: .version1
    )
    let predicate = NSPredicate { _, _ -> Bool in
      self.delegate.capturedRestoredEvent == expectedEvent && self.delegate.capturedNewEvent == nil
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    wait(for: [expectation], timeout: 20.0)
  }

  func testResolveRestoredStartTrialSubscriptionEventWithStoreKit1() {
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
    let originalTransaction = TestPaymentTransaction(identifier: "0", state: .purchased, date: now, payment: payment)
    let transaction = TestPaymentTransaction(
      identifier: "1",
      state: .restored,
      date: now,
      payment: payment,
      originalTransaction: originalTransaction
    )
    eventResolver.resolveEventFor(transaction: transaction)
    let subscriptionPeriod = IAPSubscriptionPeriod(unit: .year, numUnits: 1)
    let introOfferSubscriptionPeriod = IAPSubscriptionPeriod(unit: .month, numUnits: 6)
    let expectedEvent = IAPEvent(
      eventName: .subscribeRestore,
      productID: productID.rawValue,
      productTitle: "",
      productDescription: "",
      amount: 0,
      quantity: 1,
      currency: "USD",
      transactionID: "1",
      originalTransactionID: "0",
      transactionDate: now,
      originalTransactionDate: now,
      isVerified: false,
      isSubscription: true,
      subscriptionPeriod: subscriptionPeriod,
      isStartTrial: true,
      hasIntroductoryOffer: true,
      hasFreeTrial: true,
      introductoryOfferSubscriptionPeriod: introOfferSubscriptionPeriod,
      introductoryOfferPrice: 0.0,
      storeKitVersion: .version1
    )
    let predicate = NSPredicate { _, _ -> Bool in
      self.delegate.capturedRestoredEvent == expectedEvent && self.delegate.capturedNewEvent == nil
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    wait(for: [expectation], timeout: 20.0)
  }

  func testResolveRestoredAutoSubscriptionEventGKDisabledWithStoreKit1() {
    let productID = Self.ProductIdentifiers.autoRenewingSubscription1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    TestGateKeeperManager.gateKeepers["app_events_if_auto_log_subs"] = false
    let now = Date()
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let originalTransaction = TestPaymentTransaction(identifier: "0", state: .purchased, date: now, payment: payment)
    let transaction = TestPaymentTransaction(
      identifier: "1",
      state: .restored,
      date: now,
      payment: payment,
      originalTransaction: originalTransaction
    )
    eventResolver.resolveEventFor(transaction: transaction)
    let subscriptionPeriod = IAPSubscriptionPeriod(unit: .year, numUnits: 1)
    let expectedEvent = IAPEvent(
      eventName: .purchaseRestored,
      productID: productID.rawValue,
      productTitle: "",
      productDescription: "",
      amount: 2,
      quantity: 1,
      currency: "USD",
      transactionID: "1",
      originalTransactionID: "0",
      transactionDate: now,
      originalTransactionDate: now,
      isVerified: false,
      isSubscription: true,
      subscriptionPeriod: subscriptionPeriod,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil,
      storeKitVersion: .version1
    )
    let predicate = NSPredicate { _, _ -> Bool in
      self.delegate.capturedRestoredEvent == expectedEvent && self.delegate.capturedNewEvent == nil
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    wait(for: [expectation], timeout: 20.0)
  }

  func testResolveInitiatedCheckoutNonConsumeableWithStoreKit1() {
    let productID = Self.ProductIdentifiers.nonConsumableProduct1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(state: .purchasing, payment: payment)
    eventResolver.resolveEventFor(transaction: transaction)
    let expectedEvent = IAPEvent(
      eventName: .initiatedCheckout,
      productID: productID.rawValue,
      productTitle: "",
      productDescription: "",
      amount: 0.99,
      quantity: 1,
      currency: "USD",
      transactionID: nil,
      originalTransactionID: nil,
      transactionDate: nil,
      originalTransactionDate: nil,
      isVerified: false,
      isSubscription: false,
      subscriptionPeriod: nil,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil,
      storeKitVersion: .version1
    )
    let predicate = NSPredicate { _, _ -> Bool in
      self.delegate.capturedInitiatedCheckoutEvent == expectedEvent
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    wait(for: [expectation], timeout: 20.0)
  }

  func testResolveInitiatedCheckoutConsumablePurchaseEventWithStoreKit1() {
    let productID = Self.ProductIdentifiers.consumableProduct1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 2)
    let transaction = TestPaymentTransaction(state: .purchasing, payment: payment)
    eventResolver.resolveEventFor(transaction: transaction)
    let expectedEvent = IAPEvent(
      eventName: .initiatedCheckout,
      productID: productID.rawValue,
      productTitle: "",
      productDescription: "",
      amount: 20,
      quantity: 2,
      currency: "USD",
      transactionID: nil,
      originalTransactionID: nil,
      transactionDate: nil,
      originalTransactionDate: nil,
      isVerified: false,
      isSubscription: false,
      subscriptionPeriod: nil,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil,
      storeKitVersion: .version1
    )
    let predicate = NSPredicate { _, _ -> Bool in
      self.delegate.capturedInitiatedCheckoutEvent == expectedEvent
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    wait(for: [expectation], timeout: 20.0)
  }

  func testResolveInitiatedCheckoutNonRenewingSubscriptionEventWithStoreKit1() {
    let productID = Self.ProductIdentifiers.nonRenewingSubscription1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(state: .purchasing, payment: payment)
    eventResolver.resolveEventFor(transaction: transaction)
    let expectedEvent = IAPEvent(
      eventName: .initiatedCheckout,
      productID: productID.rawValue,
      productTitle: "",
      productDescription: "",
      amount: 5,
      quantity: 1,
      currency: "USD",
      transactionID: nil,
      originalTransactionID: nil,
      transactionDate: nil,
      originalTransactionDate: nil,
      isVerified: false,
      isSubscription: false,
      subscriptionPeriod: nil,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil,
      storeKitVersion: .version1
    )
    let predicate = NSPredicate { _, _ -> Bool in
      self.delegate.capturedInitiatedCheckoutEvent == expectedEvent
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    wait(for: [expectation], timeout: 20.0)
  }

  func testResolveInitiatedCheckoutAutoRenewingSubscriptionEventWithStoreKit1() {
    let productID = Self.ProductIdentifiers.autoRenewingSubscription1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(state: .purchasing, payment: payment)
    eventResolver.resolveEventFor(transaction: transaction)
    let subscriptionPeriod = IAPSubscriptionPeriod(unit: .year, numUnits: 1)
    let expectedEvent = IAPEvent(
      eventName: .subscribeInitiatedCheckout,
      productID: productID.rawValue,
      productTitle: "",
      productDescription: "",
      amount: 2,
      quantity: 1,
      currency: "USD",
      transactionID: nil,
      originalTransactionID: nil,
      transactionDate: nil,
      originalTransactionDate: nil,
      isVerified: false,
      isSubscription: true,
      subscriptionPeriod: subscriptionPeriod,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil,
      storeKitVersion: .version1
    )
    let predicate = NSPredicate { _, _ -> Bool in
      self.delegate.capturedInitiatedCheckoutEvent == expectedEvent
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    wait(for: [expectation], timeout: 20.0)
  }

  func testResolveInitiatedCheckoutStartTrialSubscriptionEventWithStoreKit1() {
    let productID = Self.ProductIdentifiers.autoRenewingSubscription2
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let sampleDiscount = SKPaymentDiscount(
      identifier: "FreeTrial",
      keyIdentifier: "key",
      nonce: UUID(),
      signature: "signature",
      timestamp: 1
    )
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1, discount: sampleDiscount)
    let transaction = TestPaymentTransaction(state: .purchasing, payment: payment)
    eventResolver.resolveEventFor(transaction: transaction)
    let subscriptionPeriod = IAPSubscriptionPeriod(unit: .year, numUnits: 1)
    let introOfferSubscriptionPeriod = IAPSubscriptionPeriod(unit: .month, numUnits: 6)
    let expectedEvent = IAPEvent(
      eventName: .subscribeInitiatedCheckout,
      productID: productID.rawValue,
      productTitle: "",
      productDescription: "",
      amount: 0,
      quantity: 1,
      currency: "USD",
      transactionID: nil,
      originalTransactionID: nil,
      transactionDate: nil,
      originalTransactionDate: nil,
      isVerified: false,
      isSubscription: true,
      subscriptionPeriod: subscriptionPeriod,
      isStartTrial: true,
      hasIntroductoryOffer: true,
      hasFreeTrial: true,
      introductoryOfferSubscriptionPeriod: introOfferSubscriptionPeriod,
      introductoryOfferPrice: 0.0,
      storeKitVersion: .version1
    )
    let predicate = NSPredicate { _, _ -> Bool in
      self.delegate.capturedInitiatedCheckoutEvent == expectedEvent
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    wait(for: [expectation], timeout: 20.0)
  }

  func testResolveInitiatedCheckoutAutoSubscriptionEventGKDisabledWithStoreKit1() {
    TestGateKeeperManager.gateKeepers["app_events_if_auto_log_subs"] = false
    let productID = Self.ProductIdentifiers.autoRenewingSubscription1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(state: .purchasing, payment: payment)
    let subscriptionPeriod = IAPSubscriptionPeriod(unit: .year, numUnits: 1)
    let expectedEvent = IAPEvent(
      eventName: .initiatedCheckout,
      productID: productID.rawValue,
      productTitle: "",
      productDescription: "",
      amount: 2,
      quantity: 1,
      currency: "USD",
      transactionID: nil,
      originalTransactionID: nil,
      transactionDate: nil,
      originalTransactionDate: nil,
      isVerified: false,
      isSubscription: true,
      subscriptionPeriod: subscriptionPeriod,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil,
      storeKitVersion: .version1
    )
    eventResolver.resolveEventFor(transaction: transaction)
    let predicate = NSPredicate { _, _ -> Bool in
      self.delegate.capturedInitiatedCheckoutEvent == expectedEvent
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    wait(for: [expectation], timeout: 20.0)
  }

  func testResolveFailedNonConsumeableWithStoreKit1() {
    let productID = Self.ProductIdentifiers.nonConsumableProduct1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(state: .failed, payment: payment)
    eventResolver.resolveEventFor(transaction: transaction)
    let expectedEvent = IAPEvent(
      eventName: .purchaseFailed,
      productID: productID.rawValue,
      productTitle: "",
      productDescription: "",
      amount: 0.99,
      quantity: 1,
      currency: "USD",
      transactionID: nil,
      originalTransactionID: nil,
      transactionDate: nil,
      originalTransactionDate: nil,
      isVerified: false,
      isSubscription: false,
      subscriptionPeriod: nil,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil,
      storeKitVersion: .version1
    )
    let predicate = NSPredicate { _, _ -> Bool in
      self.delegate.capturedFailedEvent == expectedEvent
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    wait(for: [expectation], timeout: 20.0)
  }

  func testResolveFailedConsumablePurchaseEventWithStoreKit1() {
    let productID = Self.ProductIdentifiers.consumableProduct1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 2)
    let transaction = TestPaymentTransaction(state: .failed, payment: payment)
    eventResolver.resolveEventFor(transaction: transaction)
    let expectedEvent = IAPEvent(
      eventName: .purchaseFailed,
      productID: productID.rawValue,
      productTitle: "",
      productDescription: "",
      amount: 20,
      quantity: 2,
      currency: "USD",
      transactionID: nil,
      originalTransactionID: nil,
      transactionDate: nil,
      originalTransactionDate: nil,
      isVerified: false,
      isSubscription: false,
      subscriptionPeriod: nil,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil,
      storeKitVersion: .version1
    )
    let predicate = NSPredicate { _, _ -> Bool in
      self.delegate.capturedFailedEvent == expectedEvent
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    wait(for: [expectation], timeout: 20.0)
  }

  func testResolveFailedNonRenewingSubscriptionEventWithStoreKit1() {
    let productID = Self.ProductIdentifiers.nonRenewingSubscription1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(state: .failed, payment: payment)
    eventResolver.resolveEventFor(transaction: transaction)
    let expectedEvent = IAPEvent(
      eventName: .purchaseFailed,
      productID: productID.rawValue,
      productTitle: "",
      productDescription: "",
      amount: 5,
      quantity: 1,
      currency: "USD",
      transactionID: nil,
      originalTransactionID: nil,
      transactionDate: nil,
      originalTransactionDate: nil,
      isVerified: false,
      isSubscription: false,
      subscriptionPeriod: nil,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil,
      storeKitVersion: .version1
    )
    let predicate = NSPredicate { _, _ -> Bool in
      self.delegate.capturedFailedEvent == expectedEvent
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    wait(for: [expectation], timeout: 20.0)
  }

  func testResolveFailedAutoRenewingSubscriptionEventWithStoreKit1() {
    let productID = Self.ProductIdentifiers.autoRenewingSubscription1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(state: .failed, payment: payment)
    eventResolver.resolveEventFor(transaction: transaction)
    let subscriptionPeriod = IAPSubscriptionPeriod(unit: .year, numUnits: 1)
    let expectedEvent = IAPEvent(
      eventName: .subscribeFailed,
      productID: productID.rawValue,
      productTitle: "",
      productDescription: "",
      amount: 2,
      quantity: 1,
      currency: "USD",
      transactionID: nil,
      originalTransactionID: nil,
      transactionDate: nil,
      originalTransactionDate: nil,
      isVerified: false,
      isSubscription: true,
      subscriptionPeriod: subscriptionPeriod,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil,
      storeKitVersion: .version1
    )
    let predicate = NSPredicate { _, _ -> Bool in
      self.delegate.capturedFailedEvent == expectedEvent
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    wait(for: [expectation], timeout: 20.0)
  }

  func testResolveFailedStartTrialSubscriptionEventWithStoreKit1() {
    let productID = Self.ProductIdentifiers.autoRenewingSubscription2
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let sampleDiscount = SKPaymentDiscount(
      identifier: "FreeTrial",
      keyIdentifier: "key",
      nonce: UUID(),
      signature: "signature",
      timestamp: 1
    )
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1, discount: sampleDiscount)
    let transaction = TestPaymentTransaction(state: .failed, payment: payment)
    eventResolver.resolveEventFor(transaction: transaction)
    let subscriptionPeriod = IAPSubscriptionPeriod(unit: .year, numUnits: 1)
    let introOfferSubscriptionPeriod = IAPSubscriptionPeriod(unit: .month, numUnits: 6)
    let expectedEvent = IAPEvent(
      eventName: .subscribeFailed,
      productID: productID.rawValue,
      productTitle: "",
      productDescription: "",
      amount: 0,
      quantity: 1,
      currency: "USD",
      transactionID: nil,
      originalTransactionID: nil,
      transactionDate: nil,
      originalTransactionDate: nil,
      isVerified: false,
      isSubscription: true,
      subscriptionPeriod: subscriptionPeriod,
      isStartTrial: true,
      hasIntroductoryOffer: true,
      hasFreeTrial: true,
      introductoryOfferSubscriptionPeriod: introOfferSubscriptionPeriod,
      introductoryOfferPrice: 0.0,
      storeKitVersion: .version1
    )
    let predicate = NSPredicate { _, _ -> Bool in
      self.delegate.capturedFailedEvent == expectedEvent
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    wait(for: [expectation], timeout: 20.0)
  }

  func testResolveFailedAutoSubscriptionEventGKDisabledWithStoreKit1() {
    TestGateKeeperManager.gateKeepers["app_events_if_auto_log_subs"] = false
    let productID = Self.ProductIdentifiers.autoRenewingSubscription1
    iapSKProductRequestFactory.stubbedResponse = SampleSKProductsResponse.getResponseFor(productID: productID)
    let payment = TestPayment(productIdentifier: productID.rawValue, quantity: 1)
    let transaction = TestPaymentTransaction(state: .failed, payment: payment)
    let subscriptionPeriod = IAPSubscriptionPeriod(unit: .year, numUnits: 1)
    let expectedEvent = IAPEvent(
      eventName: .purchaseFailed,
      productID: productID.rawValue,
      productTitle: "",
      productDescription: "",
      amount: 2,
      quantity: 1,
      currency: "USD",
      transactionID: nil,
      originalTransactionID: nil,
      transactionDate: nil,
      originalTransactionDate: nil,
      isVerified: false,
      isSubscription: true,
      subscriptionPeriod: subscriptionPeriod,
      isStartTrial: false,
      hasIntroductoryOffer: false,
      hasFreeTrial: false,
      introductoryOfferSubscriptionPeriod: nil,
      introductoryOfferPrice: nil,
      storeKitVersion: .version1
    )
    eventResolver.resolveEventFor(transaction: transaction)
    let predicate = NSPredicate { _, _ -> Bool in
      self.delegate.capturedFailedEvent == expectedEvent
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    wait(for: [expectation], timeout: 20.0)
  }
}

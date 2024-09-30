/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import XCTest

final class IAPEventTests: XCTestCase {

  func testIAPEvent() {
    let now = Date()
    let event1 = IAPEvent(
      eventName: .purchased,
      productID: "com.fbsdk.p1",
      productTitle: "Product 1",
      productDescription: "Product 1 Description",
      amount: 4.99,
      quantity: 2,
      currency: "USD",
      transactionID: "1",
      originalTransactionID: "1",
      transactionDate: now,
      originalTransactionDate: now,
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
    XCTAssertEqual(event1.eventName.rawValue, AppEvents.Name.purchased.rawValue)
    XCTAssertEqual(event1.productID, "com.fbsdk.p1")
    XCTAssertEqual(event1.productTitle, "Product 1")
    XCTAssertEqual(event1.productDescription, "Product 1 Description")
    XCTAssertEqual(event1.amount, 4.99)
    XCTAssertEqual(event1.quantity, 2)
    XCTAssertEqual(event1.currency, "USD")
    XCTAssertEqual(event1.transactionID, "1")
    XCTAssertEqual(event1.originalTransactionID, "1")
    XCTAssertEqual(event1.transactionDate, now)
    XCTAssertEqual(event1.originalTransactionDate, now)
    XCTAssertTrue(event1.isVerified)
    XCTAssertFalse(event1.isSubscription)
    XCTAssertNil(event1.subscriptionPeriod)
    XCTAssertFalse(event1.isStartTrial)
    XCTAssertFalse(event1.hasIntroductoryOffer)
    XCTAssertFalse(event1.hasFreeTrial)
    XCTAssertNil(event1.introductoryOfferSubscriptionPeriod)
    XCTAssertNil(event1.introductoryOfferPrice)
  }

  func testIAPEventNotEqualName() {
    let now = Date()
    let event1 = IAPEvent(
      eventName: .purchased,
      productID: "com.fbsdk.p1",
      productTitle: "Product 1",
      productDescription: "Product 1 Description",
      amount: 4.99,
      quantity: 1,
      currency: "USD",
      transactionID: "1",
      originalTransactionID: "1",
      transactionDate: now,
      originalTransactionDate: now,
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
    let event2 = IAPEvent(
      eventName: .purchaseRestored,
      productID: "com.fbsdk.p1",
      productTitle: "Product 1",
      productDescription: "Product 1 Description",
      amount: 4.99,
      quantity: 1,
      currency: "USD",
      transactionID: "1",
      originalTransactionID: "1",
      transactionDate: now,
      originalTransactionDate: now,
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
    XCTAssertNotEqual(event1, event2)
  }

  func testIAPEventNotEqualVerification() {
    let now = Date()
    let event1 = IAPEvent(
      eventName: .purchased,
      productID: "com.fbsdk.p1",
      productTitle: "Product 1",
      productDescription: "Product 1 Description",
      amount: 4.99,
      quantity: 1,
      currency: "USD",
      transactionID: "1",
      originalTransactionID: "1",
      transactionDate: now,
      originalTransactionDate: now,
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
    let event2 = IAPEvent(
      eventName: .purchased,
      productID: "com.fbsdk.p1",
      productTitle: "Product 1",
      productDescription: "Product 1 Description",
      amount: 4.99,
      quantity: 1,
      currency: "USD",
      transactionID: "1",
      originalTransactionID: "1",
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
      storeKitVersion: .version2
    )
    XCTAssertNotEqual(event1, event2)
  }

  func testIAPEventEqual() {
    let now = Date()
    let event1 = IAPEvent(
      eventName: .purchased,
      productID: "com.fbsdk.p1",
      productTitle: "Product 1",
      productDescription: "Product 1 Description",
      amount: 4.99,
      quantity: 1,
      currency: "USD",
      transactionID: "1",
      originalTransactionID: "1",
      transactionDate: now,
      originalTransactionDate: now,
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
    let event2 = IAPEvent(
      eventName: .purchased,
      productID: "com.fbsdk.p1",
      productTitle: "Product 1",
      productDescription: "Product 1 Description",
      amount: 4.99,
      quantity: 1,
      currency: "USD",
      transactionID: "1",
      originalTransactionID: "1",
      transactionDate: now,
      originalTransactionDate: now,
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
    XCTAssertEqual(event1, event2)
  }
}

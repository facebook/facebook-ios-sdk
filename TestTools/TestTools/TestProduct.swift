/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import StoreKit

public final class TestProduct: SKProduct {
  public static let title = "Product title"
  public static let productDescription = "Some description"
  private var stubbedID: String?
  private var stubbedTitle: String?
  private var stubbedDescription: String?
  private var stubbedPrice: NSDecimalNumber?

  public let stubbedSubscriptionPeriod: TestProductSubscriptionPeriod?
  public let stubbedDiscount: SKProductDiscount?

  public init(
    subscriptionPeriod: TestProductSubscriptionPeriod? = nil,
    discount: TestProductDiscount? = nil,
    id: String? = nil,
    title: String? = nil,
    description: String? = nil,
    price: NSDecimalNumber? = nil
  ) {
    stubbedSubscriptionPeriod = subscriptionPeriod
    stubbedDiscount = discount
    stubbedID = id
    stubbedTitle = title
    stubbedDescription = description
    stubbedPrice = price
  }

  public override var subscriptionPeriod: SKProductSubscriptionPeriod? {
    stubbedSubscriptionPeriod
  }

  public override var priceLocale: Locale {
    let localeIdentifier = NSLocale.localeIdentifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: "USD"])
    return NSLocale(localeIdentifier: localeIdentifier) as Locale
  }

  public override var productIdentifier: String {
    stubbedID ?? ""
  }

  public override var localizedTitle: String {
    stubbedTitle ?? TestProduct.title
  }

  public override var localizedDescription: String {
    stubbedDescription ?? TestProduct.productDescription
  }

  public override var introductoryPrice: SKProductDiscount? {
    stubbedDiscount
  }

  public override var discounts: [SKProductDiscount] {
    [stubbedDiscount].compactMap { $0 }
  }

  public override var price: NSDecimalNumber {
    stubbedPrice ?? 0.0
  }
}

extension TestProduct {
  public static var consumableProduct1: TestProduct {
    TestProduct(
      id: "com.fbsdk.consumable.p1",
      title: "",
      description: "",
      price: 10.0
    )
  }

  public static var nonConsumableProduct1: TestProduct {
    TestProduct(
      id: "com.fbsdk.nonconsumable.p1",
      title: "",
      description: "",
      price: 0.99
    )
  }

  public static var nonConsumableProduct2: TestProduct {
    TestProduct(
      id: "com.fbsdk.nonconsumable.p2",
      title: "",
      description: "",
      price: 0.99
    )
  }

  public static var autoRenewingSubscription1: TestProduct {
    let subscriptionPeriod = TestProductSubscriptionPeriod(
      numberOfUnits: 1,
      unit: .year
    )
    return TestProduct(
      subscriptionPeriod: subscriptionPeriod,
      id: "com.fbsdk.autorenewing.s1",
      title: "",
      description: "",
      price: 2.0
    )
  }

  public static var autoRenewingSubscription2: TestProduct {
    let actualSubscriptionPeriod = TestProductSubscriptionPeriod(
      numberOfUnits: 1,
      unit: .year
    )
    let freeSubscriptionPeriod = TestProductSubscriptionPeriod(
      numberOfUnits: 6,
      unit: .month
    )
    let discount = TestProductDiscount(
      identifier: "FreeTrial",
      paymentMode: .freeTrial,
      price: 0.0,
      subscriptionPeriod: freeSubscriptionPeriod
    )
    return TestProduct(
      subscriptionPeriod: actualSubscriptionPeriod,
      discount: discount,
      id: "com.fbsdk.autorenewing.s2",
      title: "",
      description: "",
      price: 3.0
    )
  }

  public static var nonRenewingSubscription1: TestProduct {
    TestProduct(
      id: "com.fbsdk.nonrenewing.s1",
      title: "",
      description: "",
      price: 5.0
    )
  }
}

/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@available(iOS 11.2, *)
class TestProduct: SKProduct {
  static let title = "Product title"
  static let productDescription = "Some description"

  let stubbedSubscriptionPeriod: TestProductSubscriptionPeriod?
  let stubbedDiscount: SKProductDiscount?

  init(
    subscriptionPeriod: TestProductSubscriptionPeriod? = nil,
    discount: TestProductDiscount? = nil
  ) {
    stubbedSubscriptionPeriod = subscriptionPeriod
    stubbedDiscount = discount
  }

  override var subscriptionPeriod: SKProductSubscriptionPeriod? {
    stubbedSubscriptionPeriod
  }

  override var priceLocale: Locale {
    let localeIdentifier = NSLocale.localeIdentifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: "USD"])
    return NSLocale(localeIdentifier: localeIdentifier) as Locale
  }

  override var localizedTitle: String {
    TestProduct.title
  }

  override var localizedDescription: String {
    TestProduct.productDescription
  }

  override var introductoryPrice: SKProductDiscount? {
    stubbedDiscount
  }

  override var discounts: [SKProductDiscount] {
    [stubbedDiscount].compactMap { $0 }
  }
}

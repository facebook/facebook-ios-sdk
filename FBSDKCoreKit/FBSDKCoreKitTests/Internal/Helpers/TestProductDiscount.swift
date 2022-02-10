/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@available(iOS 11.2, *)
final class TestProductDiscount: SKProductDiscount {
  let stubbedIdentifier: String
  let stubbedPaymentMode: PaymentMode
  let stubbedPrice: NSDecimalNumber
  let stubbedSubscriptionPeriod: TestProductSubscriptionPeriod

  init(
    identifier: String = "identifier",
    paymentMode: PaymentMode,
    price: NSDecimalNumber,
    subscriptionPeriod: TestProductSubscriptionPeriod
  ) {
    stubbedIdentifier = identifier
    stubbedPaymentMode = paymentMode
    stubbedPrice = price
    stubbedSubscriptionPeriod = subscriptionPeriod
  }

  override var identifier: String? {
    stubbedIdentifier
  }

  override var paymentMode: SKProductDiscount.PaymentMode {
    stubbedPaymentMode
  }

  override var price: NSDecimalNumber {
    stubbedPrice
  }

  override var subscriptionPeriod: SKProductSubscriptionPeriod {
    stubbedSubscriptionPeriod
  }
}

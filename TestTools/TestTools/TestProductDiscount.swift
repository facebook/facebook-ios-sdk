/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import StoreKit

public final class TestProductDiscount: SKProductDiscount {
  let stubbedIdentifier: String
  let stubbedPaymentMode: PaymentMode
  let stubbedPrice: NSDecimalNumber
  let stubbedSubscriptionPeriod: TestProductSubscriptionPeriod

  public init(
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

  public override var identifier: String? {
    stubbedIdentifier
  }

  public override var paymentMode: SKProductDiscount.PaymentMode {
    stubbedPaymentMode
  }

  public override var price: NSDecimalNumber {
    stubbedPrice
  }

  public override var subscriptionPeriod: SKProductSubscriptionPeriod {
    stubbedSubscriptionPeriod
  }
}

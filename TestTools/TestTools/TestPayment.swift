/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import StoreKit

@available(iOS 12.2, *)
public final class TestPayment: SKPayment {
  public let stubbedProductIdentifier: String
  public let stubbedQuantity: Int
  public let stubbedPaymentDiscount: SKPaymentDiscount?

  public init(
    productIdentifier: String,
    quantity: Int = 0,
    discount: SKPaymentDiscount? = nil
  ) {
    stubbedProductIdentifier = productIdentifier
    stubbedQuantity = quantity
    stubbedPaymentDiscount = discount
  }

  public override var productIdentifier: String {
    stubbedProductIdentifier
  }

  public override var quantity: Int {
    stubbedQuantity
  }

  @available(iOS 12.2, *)
  public override var paymentDiscount: SKPaymentDiscount? {
    stubbedPaymentDiscount
  }
}

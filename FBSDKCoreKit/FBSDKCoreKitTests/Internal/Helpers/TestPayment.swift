/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@available(iOS 12.2, *)
final class TestPayment: SKPayment {
  let stubbedProductIdentifier: String
  let stubbedQuantity: Int
  let stubbedPaymentDiscount: SKPaymentDiscount?

  init(
    productIdentifier: String,
    quantity: Int = 0,
    discount: SKPaymentDiscount? = nil
  ) {
    stubbedProductIdentifier = productIdentifier
    stubbedQuantity = quantity
    stubbedPaymentDiscount = discount
  }

  override var productIdentifier: String {
    stubbedProductIdentifier
  }

  override var quantity: Int {
    stubbedQuantity
  }

  @available(iOS 12.2, *)
  override var paymentDiscount: SKPaymentDiscount? {
    stubbedPaymentDiscount
  }
}

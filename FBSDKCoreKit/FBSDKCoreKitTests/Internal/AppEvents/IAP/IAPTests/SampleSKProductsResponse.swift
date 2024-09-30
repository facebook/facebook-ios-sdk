/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import StoreKit
import TestTools

enum SampleSKProductsResponse {
  static func getResponseFor(productID: StoreKitTestCase.ProductIdentifiers? = nil) -> SKProductsResponse {
    guard let productID else {
      return TestProductsResponse(products: [], invalidProductIdentifiers: [])
    }
    switch productID {
    case .consumableProduct1:
      return TestProductsResponse(
        products: [TestProduct.consumableProduct1],
        invalidProductIdentifiers: []
      )
    case .nonConsumableProduct1:
      return TestProductsResponse(
        products: [TestProduct.nonConsumableProduct1],
        invalidProductIdentifiers: []
      )
    case .nonConsumableProduct2:
      return TestProductsResponse(
        products: [TestProduct.nonConsumableProduct2],
        invalidProductIdentifiers: []
      )
    case .autoRenewingSubscription1:
      return TestProductsResponse(
        products: [TestProduct.autoRenewingSubscription1],
        invalidProductIdentifiers: []
      )
    case .autoRenewingSubscription2:
      return TestProductsResponse(
        products: [TestProduct.autoRenewingSubscription2],
        invalidProductIdentifiers: []
      )
    case .nonRenewingSubscription1:
      return TestProductsResponse(
        products: [TestProduct.nonRenewingSubscription1],
        invalidProductIdentifiers: []
      )
    }
  }
}

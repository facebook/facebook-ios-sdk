/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

final class TestProductsResponse: SKProductsResponse {
  private let stubbedProducts: [SKProduct]
  private let stubbedInvalidProductIdentifiers: [String]

  init(
    products: [SKProduct],
    invalidProductIdentifiers: [String]
  ) {
    stubbedProducts = products
    stubbedInvalidProductIdentifiers = invalidProductIdentifiers
  }

  override var products: [SKProduct] {
    stubbedProducts
  }

  override var invalidProductIdentifiers: [String] {
    stubbedInvalidProductIdentifiers
  }
}

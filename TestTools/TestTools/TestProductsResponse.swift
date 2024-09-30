/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import StoreKit

public final class TestProductsResponse: SKProductsResponse {
  private let stubbedProducts: [SKProduct]
  private let stubbedInvalidProductIdentifiers: [String]

  public init(
    products: [SKProduct],
    invalidProductIdentifiers: [String]
  ) {
    stubbedProducts = products
    stubbedInvalidProductIdentifiers = invalidProductIdentifiers
  }

  public override var products: [SKProduct] {
    stubbedProducts
  }

  public override var invalidProductIdentifiers: [String] {
    stubbedInvalidProductIdentifiers
  }
}

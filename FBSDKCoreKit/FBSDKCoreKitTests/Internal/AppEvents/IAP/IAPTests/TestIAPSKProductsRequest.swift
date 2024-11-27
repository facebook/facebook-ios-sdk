/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit
import Foundation

final class TestIAPSKProductsRequest: SKProductsRequest, IAPSKProductsRequesting {
  var transaction: SKPaymentTransaction?
  var stubbedResponse: SKProductsResponse?

  override init() {
    super.init()
  }

  override init(productIdentifiers: Set<String>) {
    super.init(productIdentifiers: productIdentifiers)
  }

  convenience init(
    productIdentifiers: Set<String>,
    transaction: SKPaymentTransaction,
    stubbedResponse: SKProductsResponse?
  ) {
    self.init(productIdentifiers: productIdentifiers)
    self.transaction = transaction
    self.stubbedResponse = stubbedResponse
  }

  override func start() {
    guard let stubbedResponse else {
      return
    }
    delegate?.productsRequest(self, didReceive: stubbedResponse)
  }
}

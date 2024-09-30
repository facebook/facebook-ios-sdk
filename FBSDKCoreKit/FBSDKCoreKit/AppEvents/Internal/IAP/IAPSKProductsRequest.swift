/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import StoreKit

final class IAPSKProductsRequest: SKProductsRequest, IAPSKProductsRequesting {
  var transaction: SKPaymentTransaction?

  override init() {
    super.init()
  }

  override init(productIdentifiers: Set<String>) {
    super.init(productIdentifiers: productIdentifiers)
  }

  convenience init(productIdentifiers: Set<String>, transaction: SKPaymentTransaction) {
    self.init(productIdentifiers: productIdentifiers)
    self.transaction = transaction
  }
}

/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

struct IAPSKProductsRequestFactory: IAPSKProductsRequestCreating {
  func createRequestWith(productIdentifier: String, transaction: SKPaymentTransaction) -> any IAPSKProductsRequesting {
    let productIdentifiers: Set<String> = [productIdentifier]
    return IAPSKProductsRequest(productIdentifiers: productIdentifiers, transaction: transaction)
  }
}

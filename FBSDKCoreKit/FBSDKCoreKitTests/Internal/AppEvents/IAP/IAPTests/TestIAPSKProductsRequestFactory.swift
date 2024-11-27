/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit
import Foundation

final class TestIAPSKProductsRequestFactory: NSObject, IAPSKProductsRequestCreating {
  var stubbedResponse: SKProductsResponse?

  func createRequestWith(productIdentifier: String, transaction: SKPaymentTransaction) -> any IAPSKProductsRequesting {
    TestIAPSKProductsRequest(
      productIdentifiers: [productIdentifier],
      transaction: transaction,
      stubbedResponse: stubbedResponse
    )
  }
}

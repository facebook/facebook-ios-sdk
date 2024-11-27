/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit
@testable import IAPTestsHostApp

import StoreKitTest
import XCTest

@available(iOS 15.0, *)
final class AsyncSequenceTests: StoreKitTestCase {

  func testGetValues() async throws {
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.nonConsumableProduct1.rawValue]) else {
      return
    }
    _ = try await products.first?.purchase()
    let transactions = await Transaction.all.getValues()
    var count = 0
    for await asyncTransaction in Transaction.all {
      let transaction = transactions[count]
      XCTAssertEqual(asyncTransaction, transaction)
      count += 1
    }
  }
}

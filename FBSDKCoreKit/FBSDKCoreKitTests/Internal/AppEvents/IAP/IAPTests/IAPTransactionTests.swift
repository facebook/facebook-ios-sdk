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

@available(iOS 14.0, *)
final class IAPTransactionTests: StoreKitTestCase {

  @available(iOS 17.0, *)
  func testValidIAPTransaction() async throws {
    guard let transaction =
      try? await testSession.buyProduct(identifier: Self.ProductIdentifiers.nonConsumableProduct1.rawValue) else {
      return
    }
    let iapTransaction = IAPTransaction(transaction: transaction, isVerified: true)
    XCTAssertEqual(iapTransaction.transaction, transaction)
    XCTAssertTrue(iapTransaction.isVerified)
  }

  @available(iOS 17.0, *)
  func testInvalidIAPTransaction() async throws {
    guard let transaction =
      try? await testSession.buyProduct(identifier: Self.ProductIdentifiers.nonConsumableProduct1.rawValue) else {
      return
    }
    let iapTransaction = IAPTransaction(transaction: transaction, isVerified: false)
    XCTAssertEqual(iapTransaction.transaction, transaction)
    XCTAssertFalse(iapTransaction.isVerified)
  }

  @available(iOS 15.0, *)
  func testVerificationResult() async throws {
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.nonConsumableProduct1.rawValue]) else {
      return
    }
    guard let purchaseResult = try? await products.first?.purchase() else {
      return
    }
    switch purchaseResult {
    case let .success(verificationResult):
      let iapTransaction = verificationResult.iapTransaction
      switch verificationResult {
      case let .verified(transaction):
        XCTAssertTrue(iapTransaction.isVerified)
        XCTAssertEqual(iapTransaction.transaction, transaction)
      case let .unverified(transaction, _):
        XCTAssertFalse(iapTransaction.isVerified)
        XCTAssertEqual(iapTransaction.transaction, transaction)
      }
    default:
      XCTFail("Purchase failed")
    }
  }
}

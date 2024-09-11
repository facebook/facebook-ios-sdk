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
final class TransactionTests: StoreKitTestCase {

  func testGetAllTransactions() async {
    guard let products = try? await Product.products(for: Self.allIdentifiers) else {
      return
    }
    for product in products {
      guard let purchaseResult = try? await product.purchase() else {
        return
      }
      guard let transaction = try? getIAPTransactionForPurchaseResult(result: purchaseResult) else {
        return
      }
      await transaction.transaction.finish()
    }
    let transactions = await Transaction.all.getValues()
    XCTAssertEqual(transactions.count, products.count)
  }

  func testGetCurrentEntitlements() async {
    guard let products = try? await Product.products(for: Self.allIdentifiers) else {
      return
    }
    for product in products {
      guard let purchaseResult = try? await product.purchase() else {
        return
      }
      guard let transaction = try? getIAPTransactionForPurchaseResult(result: purchaseResult) else {
        return
      }
      await transaction.transaction.finish()
    }
    let transactions = await Transaction.currentEntitlements.getValues()
    XCTAssertEqual(transactions.count, products.count)
  }

  func testGetNewCandidateTransactions() async {
    guard let products = try? await Product.products(for: Self.allIdentifiers),
          products.count == Self.allIdentifiers.count else {
      return
    }
    guard let result0 = try? await products[0].purchase(),
          let transaction0 = try? getIAPTransactionForPurchaseResult(result: result0) else {
      return
    }
    await transaction0.transaction.finish()
    IAPTransactionCache.shared.newCandidatesDate = Date()
    guard let result1 = try? await products[1].purchase(),
          let transaction1 = try? getIAPTransactionForPurchaseResult(result: result1) else {
      return
    }
    await transaction1.transaction.finish()
    do {
      try testSession.refundTransaction(identifier: UInt(transaction1.transaction.id))
    } catch {
      return
    }
    let result2 = try? await products[2].purchase()
    guard result2 != nil else {
      return
    }
    guard let result3 = try? await products[3].purchase(),
          let transaction3 = try? getIAPTransactionForPurchaseResult(result: result3) else {
      return
    }
    await transaction3.transaction.finish()
    var candidateTransactions = await Transaction.getNewCandidateTransactions()
    XCTAssertEqual(candidateTransactions.count, 1)
    XCTAssertEqual(candidateTransactions.first?.iapTransaction.transaction.id, transaction3.transaction.id)
    IAPTransactionCache.shared.addTransaction(transactionID: transaction3.transaction.id, eventName: .purchased)
    candidateTransactions = await Transaction.getNewCandidateTransactions()
    XCTAssertEqual(candidateTransactions.count, 0)
  }
}

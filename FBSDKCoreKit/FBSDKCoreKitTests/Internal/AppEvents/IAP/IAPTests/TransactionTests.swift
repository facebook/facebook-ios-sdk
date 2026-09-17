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

  // StoreKit does not promise that `Product.products(for:)` returns products in
  // the order they were requested, and on iOS 27 it does not. Look each product
  // up by identifier instead of indexing into the result.
  private func product(
    _ identifier: ProductIdentifiers,
    in products: [Product]
  ) throws -> Product {
    try XCTUnwrap(
      products.first { $0.id == identifier.rawValue },
      "No product for \(identifier.rawValue) in \(products.map(\.id))"
    )
  }

  private func purchaseAndFinish(_ product: Product) async throws -> IAPTransaction {
    let result = try await product.purchase()
    let iapTransaction = try getIAPTransactionForPurchaseResult(result: result)
    await iapTransaction.transaction.finish()
    return iapTransaction
  }

  /// Skips, rather than silently passing, when the StoreKit test session cannot
  /// vend the configured products. On some simulator runtimes `Product.products(for:)`
  /// returns nothing at all, and the previous `guard ... else { return }` form
  /// reported those runs as passes while asserting nothing.
  private func allProducts() async throws -> [Product] {
    let products = try await Product.products(for: Self.allIdentifiers)
    try XCTSkipUnless(
      products.count == Self.allIdentifiers.count,
      "StoreKit test session vended \(products.count) of \(Self.allIdentifiers.count) "
        + "configured products; skipping rather than reporting a vacuous pass"
    )
    return products
  }

  func testGetAllTransactions() async throws {
    let products = try await allProducts()
    for product in products {
      _ = try await purchaseAndFinish(product)
    }
    let transactions = await Transaction.all.getValues()
    let expectedCount = products.count - 1 // Cannot observe Consumables by default
    XCTAssertEqual(transactions.count, expectedCount)
  }

  func testGetCurrentEntitlements() async throws {
    let products = try await allProducts()
    for product in products {
      _ = try await purchaseAndFinish(product)
    }
    let transactions = await Transaction.currentEntitlements.getValues()
    let expectedCount = products.count - 1 // Cannot observe Consumables by default
    XCTAssertEqual(transactions.count, expectedCount)
  }

  func testGetNewCandidateTransactions() async throws {
    let products = try await allProducts()

    // Each product plays a specific role, one per exclusion path in
    // `Transaction.getNewCandidateTransactions()`, plus the one transaction that
    // is expected to survive all of them.
    let purchasedBeforeCutoff = try product(.consumableProduct1, in: products)
    let refunded = try product(.nonConsumableProduct1, in: products)
    let neverFinished = try product(.nonConsumableProduct2, in: products)
    let expected = try product(.autoRenewingSubscription1, in: products)

    // Excluded by the `newCandidatesDate` check: purchased before the cutoff.
    _ = try await purchaseAndFinish(purchasedBeforeCutoff)
    IAPTransactionCache.shared.newCandidatesDate = Date()

    // Excluded by the `revocationDate` check.
    let refundedTransaction = try await purchaseAndFinish(refunded)
    try testSession.refundTransaction(identifier: UInt(refundedTransaction.transaction.id))

    // Excluded by the unfinished check: deliberately never finished.
    let unfinishedResult = try await neverFinished.purchase()
    _ = try getIAPTransactionForPurchaseResult(result: unfinishedResult)

    let expectedTransaction = try await purchaseAndFinish(expected)

    var candidateTransactions = await Transaction.getNewCandidateTransactions()

    // A failure here is almost always StoreKit disagreeing about which
    // transactions are unfinished, so report that state rather than a bare count.
    let unfinishedIDs = await Transaction.unfinished.getValues().map(\.iapTransaction.transaction.id)
    let allIDs = await Transaction.all.getValues().map(\.iapTransaction.transaction.id)
    let state = "candidates=\(candidateTransactions.map(\.iapTransaction.transaction.id)) "
      + "unfinished=\(unfinishedIDs) all=\(allIDs) expected=\(expectedTransaction.transaction.id)"

    // Known StoreKit discrepancy on iOS 27, tracked in T288963466: a non-consumable
    // that was purchased and never finished is absent from `Transaction.unfinished`,
    // while an auto-renewable subscription that was finished is present in it. The
    // filter in `Transaction.getNewCandidateTransactions()` therefore keeps the
    // wrong transaction and drops the right one. Strict on purpose: once the
    // discrepancy is fixed this reports "expected failure did not occur", which
    // forces the annotation to be removed instead of quietly outliving the bug.
    XCTExpectFailure(
      "iOS 27 Transaction.unfinished misreports unfinished transactions (T288963466)",
      strict: true
    )

    XCTAssertEqual(candidateTransactions.count, 1, state)
    XCTAssertEqual(
      candidateTransactions.first?.iapTransaction.transaction.id,
      expectedTransaction.transaction.id,
      state
    )

    // Once recorded in the cache it is no longer a candidate.
    IAPTransactionCache.shared.addTransaction(
      transactionID: String(expectedTransaction.transaction.id),
      eventName: .purchased,
      productID: expectedTransaction.transaction.productID
    )
    candidateTransactions = await Transaction.getNewCandidateTransactions()
    XCTAssertEqual(candidateTransactions.count, 0)
  }

  func testGetNewCandidateTransactionsWithExpiredSubscription() async throws {
    guard #available(iOS 17.0, *) else {
      throw XCTSkip("SKTestSession.buyProduct / expireSubscription require iOS 17")
    }

    let identifier = ProductIdentifiers.autoRenewingSubscription1.rawValue
    let transaction = try await testSession.buyProduct(identifier: identifier)
    await transaction.finish()
    try testSession.expireSubscription(productIdentifier: identifier)

    let candidateTransactions = await Transaction.getNewCandidateTransactions()
    XCTAssertEqual(candidateTransactions.count, 0)
  }
}

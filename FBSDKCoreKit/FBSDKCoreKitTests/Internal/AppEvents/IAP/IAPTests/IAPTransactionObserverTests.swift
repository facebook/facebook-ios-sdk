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
final class IAPTransactionObserverTests: StoreKitTestCase {

  override func setUp() async throws {
    try await super.setUp()
    IAPTransactionObserver.shared.reset()
    IAPTransactionObserver.shared.configuredDependencies = .init(
      iapTransactionLoggingFactory: TestIAPTransactionLoggingFactory()
    )
    IAPTransactionObserver.shared.setObservationTime(time: 10_000_000_000)
    IAPTransactionCache.shared.reset()
    TestIAPTransactionLogger.reset()
  }

  func testObserveRestoredPurchases() async {
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.nonConsumableProduct1.rawValue]) else {
      return
    }
    guard let result = try? await products.first?.purchase() else {
      return
    }
    guard let iapTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return
    }
    await iapTransaction.transaction.finish()
    IAPTransactionObserver.shared.startObserving()
    let predicate = NSPredicate { _, _ -> Bool in
      let hasRestored = IAPTransactionCache.shared.hasRestoredPurchases
      let didRestore = TestIAPTransactionLogger.restoredTransactions.contains {
        $0.transaction.id == iapTransaction.transaction.id
      }
      return hasRestored && didRestore && TestIAPTransactionLogger.newTransactions.isEmpty
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    await fulfillment(of: [expectation], timeout: 20.0)
  }

  func testObserveEmptyRestoredPurchases() async {
    IAPTransactionObserver.shared.startObserving()
    let predicate = NSPredicate { _, _ -> Bool in
      let hasRestored = IAPTransactionCache.shared.hasRestoredPurchases
      let noTransactions = TestIAPTransactionLogger.restoredTransactions.isEmpty &&
        TestIAPTransactionLogger.newTransactions.isEmpty
      return hasRestored && noTransactions
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    await fulfillment(of: [expectation], timeout: 20.0)
  }

  func testAlreadyObservedRestoredPurchases() async {
    IAPTransactionCache.shared.hasRestoredPurchases = true
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.nonConsumableProduct1.rawValue]) else {
      return
    }
    guard let result = try? await products.first?.purchase() else {
      return
    }
    guard let iapTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return
    }
    await iapTransaction.transaction.finish()
    IAPTransactionObserver.shared.startObserving()
    let predicate = NSPredicate { _, _ -> Bool in
      TestIAPTransactionLogger.restoredTransactions.isEmpty && !TestIAPTransactionLogger.newTransactions.isEmpty
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    await fulfillment(of: [expectation], timeout: 20.0)
  }

  func testObserveNewTransactionsAfterTransactionMade() async {
    IAPTransactionCache.shared.hasRestoredPurchases = true
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.nonConsumableProduct1.rawValue]) else {
      return
    }
    guard let result = try? await products.first?.purchase() else {
      return
    }
    guard let iapTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return
    }
    await iapTransaction.transaction.finish()
    let now = Date()
    IAPTransactionObserver.shared.startObserving()
    let predicate = NSPredicate { _, _ -> Bool in
      let didLog = TestIAPTransactionLogger.newTransactions.contains {
        $0.transaction.id == iapTransaction.transaction.id
      }
      guard let newCandidateDate = IAPTransactionCache.shared.newCandidatesDate else {
        return false
      }
      let dateCheck = newCandidateDate >= now
      return TestIAPTransactionLogger.restoredTransactions.isEmpty && didLog && dateCheck
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    await fulfillment(of: [expectation], timeout: 20.0)
  }

  func testObserveNewTransactionsBeforeTransactionMade() async {
    IAPTransactionCache.shared.hasRestoredPurchases = true
    IAPTransactionObserver.shared.startObserving()
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.nonConsumableProduct1.rawValue]) else {
      return
    }
    guard let result = try? await products.first?.purchase() else {
      return
    }
    guard let iapTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return
    }
    await iapTransaction.transaction.finish()
    let now = Date()
    let predicate = NSPredicate { _, _ -> Bool in
      let didLog = TestIAPTransactionLogger.newTransactions.contains {
        $0.transaction.id == iapTransaction.transaction.id
      }
      guard let newCandidateDate = IAPTransactionCache.shared.newCandidatesDate else {
        return false
      }
      let dateCheck = newCandidateDate >= now
      return TestIAPTransactionLogger.restoredTransactions.isEmpty && didLog && dateCheck
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    await fulfillment(of: [expectation], timeout: 20.0)
  }

  func testObserveEmptyNewTransactions() async {
    IAPTransactionCache.shared.hasRestoredPurchases = true
    IAPTransactionObserver.shared.startObserving()
    let predicate = NSPredicate { _, _ -> Bool in
      let didNotObserve = TestIAPTransactionLogger.newTransactions.isEmpty
      let newCandidateDate = IAPTransactionCache.shared.newCandidatesDate
      return didNotObserve && newCandidateDate == nil
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    await fulfillment(of: [expectation], timeout: 20.0)
  }

  func testObserveNewTransactionsOldDate() async {
    IAPTransactionCache.shared.hasRestoredPurchases = true
    guard let products =
      try? await Product.products(for: [Self.ProductIdentifiers.nonConsumableProduct1.rawValue]) else {
      return
    }
    guard let result = try? await products.first?.purchase() else {
      return
    }
    guard let iapTransaction = try? getIAPTransactionForPurchaseResult(result: result) else {
      return
    }
    await iapTransaction.transaction.finish()
    let now = Date()
    IAPTransactionCache.shared.newCandidatesDate = now
    IAPTransactionObserver.shared.startObserving()
    let predicate = NSPredicate { _, _ -> Bool in
      let didNotObserve = TestIAPTransactionLogger.newTransactions.isEmpty
      let newCandidateDate = IAPTransactionCache.shared.newCandidatesDate
      return didNotObserve && newCandidateDate == now
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    await fulfillment(of: [expectation], timeout: 20.0)
  }

  func testObserveRestoredAndNewTransactions() async {
    let now = Date()
    let productIDs = [
      Self.ProductIdentifiers.nonConsumableProduct1.rawValue,
      Self.ProductIdentifiers.nonRenewingSubscription1.rawValue,
    ]
    guard let products = try? await Product.products(for: productIDs) else {
      return
    }
    guard let result1 = try? await products.first?.purchase() else {
      return
    }
    guard let iapTransaction1 = try? getIAPTransactionForPurchaseResult(result: result1) else {
      return
    }
    await iapTransaction1.transaction.finish()
    IAPTransactionObserver.shared.startObserving()
    guard let result2 = try? await products.last?.purchase() else {
      return
    }
    guard let iapTransaction2 = try? getIAPTransactionForPurchaseResult(result: result2) else {
      return
    }
    await iapTransaction2.transaction.finish()
    let predicate = NSPredicate { _, _ -> Bool in
      let didRestore = TestIAPTransactionLogger.restoredTransactions.contains {
        $0.transaction.id == iapTransaction1.transaction.id
      }
      let didObserveNew = TestIAPTransactionLogger.newTransactions.contains {
        $0.transaction.id == iapTransaction2.transaction.id
      }
      let hasRestored = IAPTransactionCache.shared.hasRestoredPurchases
      var dateCheck = false
      if let newCandidateDate = IAPTransactionCache.shared.newCandidatesDate {
        dateCheck = newCandidateDate >= now
      }
      return didRestore && hasRestored && didObserveNew && dateCheck
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    await fulfillment(of: [expectation], timeout: 30.0)
  }
}

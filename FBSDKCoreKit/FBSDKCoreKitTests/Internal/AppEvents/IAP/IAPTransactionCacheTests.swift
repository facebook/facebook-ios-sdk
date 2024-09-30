/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import XCTest

final class IAPTransactionCacheTests: XCTestCase {

  override func tearDown() {
    IAPTransactionCache.shared.reset()
    super.tearDown()
  }

  func testInitialState() {
    XCTAssertIdentical(IAPTransactionCache.shared.defaultDependencies?.dataStore, UserDefaults.standard)
    XCTAssertNil(IAPTransactionCache.shared.configuredDependencies)
    XCTAssertFalse(IAPTransactionCache.shared.hasRestoredPurchases)
    XCTAssertFalse(UserDefaults.standard.fb_bool(forKey: IAPConstants.restoredPurchasesCacheKey))
    XCTAssertTrue(IAPTransactionCache.shared.getLoggedTransactions().isEmpty)
    XCTAssertTrue(IAPTransactionCache.shared.getPersistedTransactions().isEmpty)
  }

  func testCachedTransactionCodable() {
    let cachedTransaction = IAPTransactionCache.IAPCachedTransaction(
      transactionID: "1",
      eventName: AppEvents.Name.purchased.rawValue
    )
    guard let encoded = try? JSONEncoder().encode(cachedTransaction) else {
      XCTFail("Failed to encode cachedTransaction")
      return
    }
    UserDefaults.standard.fb_setObject(encoded, forKey: "test")
    guard let data = UserDefaults.standard.fb_data(forKey: "test") else {
      XCTFail("No data persisted")
      return
    }
    guard let result = try? JSONDecoder().decode(IAPTransactionCache.IAPCachedTransaction.self, from: data) else {
      XCTFail("Failed to decode cachedTransaction")
      return
    }
    XCTAssertEqual(result, cachedTransaction)
  }

  func testHasRestoredPurchases() {
    IAPTransactionCache.shared.hasRestoredPurchases = true
    XCTAssertTrue(IAPTransactionCache.shared.hasRestoredPurchases)
    XCTAssertTrue(UserDefaults.standard.fb_bool(forKey: IAPConstants.restoredPurchasesCacheKey))
    IAPTransactionCache.shared.hasRestoredPurchases = false
    XCTAssertFalse(IAPTransactionCache.shared.hasRestoredPurchases)
    XCTAssertFalse(UserDefaults.standard.fb_bool(forKey: IAPConstants.restoredPurchasesCacheKey))
  }

  func testNewCandidatesDate() {
    XCTAssertNil(IAPTransactionCache.shared.newCandidatesDate)
    let now = Date()
    IAPTransactionCache.shared.newCandidatesDate = now
    let persisted = UserDefaults.standard.fb_object(forKey: IAPConstants.newCandidatesDateCacheKey) as? Date
    XCTAssertEqual(IAPTransactionCache.shared.newCandidatesDate, now)
    XCTAssertEqual(persisted, now)
  }

  func testAddTransaction() {
    IAPTransactionCache.shared.addTransaction(transactionID: "1", eventName: AppEvents.Name.purchased)
    IAPTransactionCache.shared.addTransaction(transactionID: "1", eventName: AppEvents.Name.purchased)
    IAPTransactionCache.shared.addTransaction(transactionID: "1", eventName: AppEvents.Name.purchaseRestored)
    IAPTransactionCache.shared.addTransaction(transactionID: "2", eventName: AppEvents.Name.purchased)
    XCTAssertTrue(IAPTransactionCache.shared.contains(transactionID: "1", eventName: AppEvents.Name.purchased))
    XCTAssertTrue(IAPTransactionCache.shared.contains(transactionID: "1", eventName: AppEvents.Name.purchaseRestored))
    XCTAssertTrue(IAPTransactionCache.shared.contains(transactionID: "2", eventName: AppEvents.Name.purchased))
    let persistedTransactions = IAPTransactionCache.shared.getPersistedTransactions()
    let loggedTransactions = IAPTransactionCache.shared.getLoggedTransactions()
    XCTAssertEqual(persistedTransactions, loggedTransactions)
    XCTAssertEqual(persistedTransactions.count, 3)
    let cachedTransaction = IAPTransactionCache.IAPCachedTransaction(
      transactionID: "1",
      eventName: AppEvents.Name.purchased.rawValue
    )
    XCTAssertTrue(persistedTransactions.contains(cachedTransaction))
  }

  func testRemoveTransaction() {
    IAPTransactionCache.shared.addTransaction(transactionID: "1", eventName: AppEvents.Name.purchased)
    IAPTransactionCache.shared.addTransaction(transactionID: "1", eventName: AppEvents.Name.purchaseRestored)
    IAPTransactionCache.shared.addTransaction(transactionID: "2", eventName: AppEvents.Name.purchased)
    XCTAssertTrue(IAPTransactionCache.shared.contains(transactionID: "1", eventName: AppEvents.Name.purchased))
    XCTAssertTrue(IAPTransactionCache.shared.contains(transactionID: "1", eventName: AppEvents.Name.purchaseRestored))
    XCTAssertTrue(IAPTransactionCache.shared.contains(transactionID: "2", eventName: AppEvents.Name.purchased))
    XCTAssertEqual(IAPTransactionCache.shared.getPersistedTransactions().count, 3)

    IAPTransactionCache.shared.removeTransaction(transactionID: "1", eventName: AppEvents.Name.purchased)
    XCTAssertFalse(IAPTransactionCache.shared.contains(transactionID: "1", eventName: AppEvents.Name.purchased))
    XCTAssertTrue(IAPTransactionCache.shared.contains(transactionID: "1", eventName: AppEvents.Name.purchaseRestored))
    XCTAssertTrue(IAPTransactionCache.shared.contains(transactionID: "2", eventName: AppEvents.Name.purchased))
    XCTAssertEqual(IAPTransactionCache.shared.getPersistedTransactions().count, 2)

    IAPTransactionCache.shared.removeTransaction(transactionID: "1", eventName: AppEvents.Name.purchaseRestored)
    XCTAssertFalse(IAPTransactionCache.shared.contains(transactionID: "1", eventName: AppEvents.Name.purchased))
    XCTAssertFalse(IAPTransactionCache.shared.contains(transactionID: "1", eventName: AppEvents.Name.purchaseRestored))
    XCTAssertTrue(IAPTransactionCache.shared.contains(transactionID: "2", eventName: AppEvents.Name.purchased))
    XCTAssertEqual(IAPTransactionCache.shared.getPersistedTransactions().count, 1)

    IAPTransactionCache.shared.removeTransaction(transactionID: "2", eventName: AppEvents.Name.purchased)
    XCTAssertFalse(IAPTransactionCache.shared.contains(transactionID: "1", eventName: AppEvents.Name.purchased))
    XCTAssertFalse(IAPTransactionCache.shared.contains(transactionID: "1", eventName: AppEvents.Name.purchaseRestored))
    XCTAssertFalse(IAPTransactionCache.shared.contains(transactionID: "2", eventName: AppEvents.Name.purchased))
    XCTAssertEqual(IAPTransactionCache.shared.getPersistedTransactions().count, 0)
  }

  func testContainsTransaction() {
    IAPTransactionCache.shared.addTransaction(transactionID: "1", eventName: AppEvents.Name.purchased)
    XCTAssertFalse(IAPTransactionCache.shared.contains(transactionID: "1", eventName: AppEvents.Name.purchaseRestored))
    XCTAssertTrue(IAPTransactionCache.shared.contains(transactionID: "1", eventName: AppEvents.Name.purchased))
    XCTAssertTrue(IAPTransactionCache.shared.contains(transactionID: "1"))
    IAPTransactionCache.shared.removeTransaction(transactionID: "1", eventName: AppEvents.Name.purchased)
    XCTAssertFalse(IAPTransactionCache.shared.contains(transactionID: "1", eventName: AppEvents.Name.purchased))
    XCTAssertFalse(IAPTransactionCache.shared.contains(transactionID: "1"))
  }
}

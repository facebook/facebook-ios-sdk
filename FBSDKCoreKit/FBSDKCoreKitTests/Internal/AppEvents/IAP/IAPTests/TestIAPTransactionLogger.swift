/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit
import Foundation

// MARK: - Store Kit 1

final class TestIAPTransactionLogger: IAPTransactionLogging {
  static var storeKit1Transactions: [SKPaymentTransaction] = []

  func logTransaction(_ transaction: SKPaymentTransaction) {
    synchronized(self) {
      Self.storeKit1Transactions.append(transaction)
    }
  }

  private static func resetStoreKit1() {
    storeKit1Transactions = []
  }
}

// MARK: - Store Kit 2

@available(iOS 15.0, *)
extension TestIAPTransactionLogger {
  static var newStoreKit2Transactions: [IAPTransaction] = []
  static var restoredStoreKit2Transactions: [IAPTransaction] = []

  func logNewTransaction(_ transaction: IAPTransaction) async {
    synchronized(self) {
      Self.newStoreKit2Transactions.append(transaction)
      IAPTransactionCache.shared.addTransaction(transactionID: String(transaction.transaction.id), eventName: .purchased)
    }
  }

  func logRestoredTransaction(_ transaction: IAPTransaction) async {
    synchronized(self) {
      Self.restoredStoreKit2Transactions.append(transaction)
      let restored = AppEvents.Name(rawValue: "fb_mobile_purchase_restored")
      IAPTransactionCache.shared.addTransaction(transactionID: String(transaction.transaction.id), eventName: restored)
    }
  }

  private static func resetStoreKit2() {
    newStoreKit2Transactions = []
    restoredStoreKit2Transactions = []
  }
}

extension TestIAPTransactionLogger {
  static func reset() {
    if #available(iOS 15.0, *) {
      resetStoreKit2()
    }
    resetStoreKit1()
  }
}

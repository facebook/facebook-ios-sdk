/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit
import Foundation

@available(iOS 15.0, *)
final class TestIAPTransactionLogger: IAPTransactionLogging {

  static var newTransactions: [IAPTransaction] = []
  static var restoredTransactions: [IAPTransaction] = []

  func logNewTransaction(_ transaction: IAPTransaction) async {
    synchronized(self) {
      Self.newTransactions.append(transaction)
      IAPTransactionCache.shared.addTransaction(transactionID: String(transaction.transaction.id), eventName: .purchased)
    }
  }

  func logRestoredTransaction(_ transaction: IAPTransaction) async {
    synchronized(self) {
      Self.restoredTransactions.append(transaction)
      let restored = AppEvents.Name(rawValue: "fb_mobile_purchase_restored")
      IAPTransactionCache.shared.addTransaction(transactionID: String(transaction.transaction.id), eventName: restored)
    }
  }

  static func reset() {
    newTransactions = []
    restoredTransactions = []
  }
}

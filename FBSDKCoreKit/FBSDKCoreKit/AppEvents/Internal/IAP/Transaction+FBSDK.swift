/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import StoreKit

@available(iOS 15.0, *)
extension Transaction {
  static func getNewCandidateTransactions() async -> [VerificationResult<Transaction>] {
    let unfinishedTransactionIDs = await Transaction.unfinished.getValues().map { result in
      result.iapTransaction.transaction.id
    }
    let transactionsToConsider = await Transaction.all.getValues()

    let candidateTransactions = transactionsToConsider.filter { result in
      let transaction = result.iapTransaction.transaction
      let id = transaction.id
      var dateCheck = true
      if let candidateDate = IAPTransactionCache.shared.newCandidatesDate {
        dateCheck = transaction.purchaseDate > candidateDate
      }
      let now = Date()
      return transaction.revocationDate == nil &&
        transaction.expirationDate ?? now >= now &&
        dateCheck &&
        !unfinishedTransactionIDs.contains(id) &&
        !IAPTransactionCache.shared.contains(transactionID: String(id))
    }
    return candidateTransactions
  }
}

@available(iOS 15.0, *)
extension Transaction {
  var isSubscription: Bool {
    productType == .autoRenewable
  }
}

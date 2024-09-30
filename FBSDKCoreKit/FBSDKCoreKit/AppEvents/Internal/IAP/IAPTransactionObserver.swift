/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import StoreKit

final class IAPTransactionObserver: NSObject {

  var configuredDependencies: ObjectDependencies?
  var defaultDependencies: ObjectDependencies? = .init(
    iapTransactionLoggingFactory: IAPTransactionLoggingFactory()
  )

  private var isObservingStoreKit2Transactions = false
  private var anyTransactionListenerTask: Any?
  private var observationTime: UInt64 = 3_600_000_000_000

  static let shared = IAPTransactionObserver()

  private override init() {
    super.init()
  }

  deinit {
    stopObserving()
  }
}

// MARK: - DependentAsObject

extension IAPTransactionObserver: DependentAsObject {
  struct ObjectDependencies {
    var iapTransactionLoggingFactory: IAPTransactionLoggingCreating
  }
}

// MARK: - Public APIs

extension IAPTransactionObserver {
  func startObserving() {
    if #available(iOS 15.0, *) {
      startObservingStoreKit2()
    }
  }

  func stopObserving() {
    if #available(iOS 15.0, *) {
      stopObservingStoreKit2()
    }
  }
}

// MARK: - Store Kit 2

@available(iOS 15.0, *)
extension IAPTransactionObserver {
  private var transactionListenerTask: Task<Void, Error>? {
    anyTransactionListenerTask as? Task<Void, Error>
  }

  private func checkForRestoredPurchases() async {
    guard isObservingStoreKit2Transactions else {
      return
    }
    guard !IAPTransactionCache.shared.hasRestoredPurchases else {
      return
    }
    for transactionResult in await Transaction.currentEntitlements.getValues() {
      await handleRestoredTransaction(transaction: transactionResult.iapTransaction)
    }
    IAPTransactionCache.shared.hasRestoredPurchases = true
  }

  private func observeNewTransactions() async {
    guard isObservingStoreKit2Transactions else {
      return
    }
    let newTransactions = await Transaction.getNewCandidateTransactions().sorted { lhs, rhs in
      lhs.iapTransaction.transaction.purchaseDate < rhs.iapTransaction.transaction.purchaseDate
    }
    guard !newTransactions.isEmpty else {
      return
    }
    for transactionResult in newTransactions {
      await handleNewTransaction(transaction: transactionResult.iapTransaction)
    }
    IAPTransactionCache.shared.newCandidatesDate = Date()
  }

  private func handleRestoredTransaction(transaction: IAPTransaction) async {
    guard let dependencies = try? getDependencies() else {
      return
    }
    let logger = dependencies.iapTransactionLoggingFactory.createIAPTransactionLogging()
    await logger.logRestoredTransaction(transaction)
  }

  private func handleNewTransaction(transaction: IAPTransaction) async {
    guard let dependencies = try? getDependencies() else {
      return
    }
    let logger = dependencies.iapTransactionLoggingFactory.createIAPTransactionLogging()
    await logger.logNewTransaction(transaction)
  }

  private func startObservingStoreKit2() {
    synchronized(self) {
      guard !isObservingStoreKit2Transactions else {
        return
      }
      isObservingStoreKit2Transactions = true
      anyTransactionListenerTask = Task {
        await checkForRestoredPurchases()
        while true {
          await observeNewTransactions()
          try await Task.sleep(nanoseconds: observationTime)
        }
      }
    }
  }

  private func stopObservingStoreKit2() {
    synchronized(self) {
      guard isObservingStoreKit2Transactions else {
        return
      }
      transactionListenerTask?.cancel()
      isObservingStoreKit2Transactions = false
    }
  }
}

// MARK: - Testing

#if DEBUG
@available(iOS 15.0, *)
extension IAPTransactionObserver {
  func reset() {
    stopObserving()
    isObservingStoreKit2Transactions = false
    anyTransactionListenerTask = nil
    observationTime = 60_000_000_000
  }

  func setObservationTime(time: UInt64) {
    observationTime = time
  }
}
#endif

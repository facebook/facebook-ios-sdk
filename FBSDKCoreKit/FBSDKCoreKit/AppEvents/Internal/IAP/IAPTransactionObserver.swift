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
final class IAPTransactionObserver: NSObject {

  var configuredDependencies: ObjectDependencies?
  var defaultDependencies: ObjectDependencies? = .init(
    iapTransactionLoggingFactory: IAPTransactionLoggingFactory()
  )

  private var isObservingTransactions = false
  private var transactionListenerTask: Task<Void, Error>?
  private var observationTime: UInt64 = 3_600_000_000_000

  static let shared = IAPTransactionObserver()

  private override init() {
    super.init()
  }

  deinit {
    stopObserving()
  }
}

// MARK: - Private Methods

@available(iOS 15.0, *)
extension IAPTransactionObserver {
  private func checkForRestoredPurchases() async {
    guard isObservingTransactions else {
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
    guard isObservingTransactions else {
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
}

// MARK: - Public APIs

@available(iOS 15.0, *)
extension IAPTransactionObserver {
  func startObserving() {
    synchronized(self) {
      guard !isObservingTransactions else {
        return
      }
      isObservingTransactions = true
      transactionListenerTask = Task {
        await checkForRestoredPurchases()
        while true {
          await observeNewTransactions()
          try await Task.sleep(nanoseconds: observationTime)
        }
      }
    }
  }

  func stopObserving() {
    synchronized(self) {
      guard isObservingTransactions else {
        return
      }
      transactionListenerTask?.cancel()
      isObservingTransactions = false
    }
  }
}

// MARK: - DependentAsObject

@available(iOS 15.0, *)
extension IAPTransactionObserver: DependentAsObject {
  struct ObjectDependencies {
    var iapTransactionLoggingFactory: IAPTransactionLoggingCreating
  }
}

// MARK: - Testing

#if DEBUG
@available(iOS 15.0, *)
extension IAPTransactionObserver {
  func reset() {
    stopObserving()
    isObservingTransactions = false
    transactionListenerTask = nil
    observationTime = 60_000_000_000
  }

  func setObservationTime(time: UInt64) {
    observationTime = time
  }
}
#endif

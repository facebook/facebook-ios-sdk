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
    iapTransactionLoggingFactory: IAPTransactionLoggingFactory(),
    paymentQueue: SKPaymentQueue.default(),
    appEventsConfigurationProvider: _AppEventsConfigurationManager.shared
  )

  private var isObservingStoreKit1Transactions = false
  private var isObservingStoreKit2Transactions = false
  private var anyTransactionListenerTask: Any?
  private var observationTime: UInt64 = IAPConstants.defaultIAPObservationTime

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
    var paymentQueue: SKPaymentQueue
    var appEventsConfigurationProvider: _AppEventsConfigurationProviding
  }
}

// MARK: - Public APIs

extension IAPTransactionObserver {
  func startObserving() {
    if IAPTransactionCache.shared.newCandidatesDate == nil {
      IAPTransactionCache.shared.newCandidatesDate = Date()
    }
    if #available(iOS 15.0, *) {
      startObservingStoreKit2()
    }
    startObervingStoreKit1()
  }

  func stopObserving() {
    if #available(iOS 15.0, *) {
      stopObservingStoreKit2()
    }
    stopObservingStoreKit1()
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
    IAPTransactionCache.shared.newCandidatesDate = newTransactions.last?.iapTransaction.transaction.purchaseDate ??
      Date()
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
      observationTime = IAPConstants.defaultIAPObservationTime
      if let dependencies = try? getDependencies() {
        observationTime = dependencies.appEventsConfigurationProvider.cachedAppEventsConfiguration.iapObservationTime
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

// MARK: - Store Kit 1

extension IAPTransactionObserver: SKPaymentTransactionObserver {
  private func startObervingStoreKit1() {
    synchronized(self) {
      guard !isObservingStoreKit1Transactions else {
        return
      }
      guard let dependencies = try? getDependencies() else {
        return
      }
      dependencies.paymentQueue.add(self)
      isObservingStoreKit1Transactions = true
    }
  }

  private func stopObservingStoreKit1() {
    synchronized(self) {
      guard isObservingStoreKit1Transactions else {
        return
      }
      guard let dependencies = try? getDependencies() else {
        return
      }
      dependencies.paymentQueue.remove(self)
      isObservingStoreKit1Transactions = false
    }
  }

  private func handleTransaction(_ transaction: SKPaymentTransaction) {
    guard let dependencies = try? getDependencies() else {
      return
    }
    let logger = dependencies.iapTransactionLoggingFactory.createIAPTransactionLogging()
    logger.logTransaction(transaction)
  }

  func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    for transaction in transactions {
      switch transaction.transactionState {
      case .purchasing, .purchased, .failed, .restored:
        handleTransaction(transaction)
      case .deferred:
        break
      @unknown default:
        break
      }
    }
  }
}

// MARK: - Testing

#if DEBUG
extension IAPTransactionObserver {
  func reset() {
    stopObserving()
    isObservingStoreKit2Transactions = false
    anyTransactionListenerTask = nil
    observationTime = IAPConstants.defaultIAPObservationTime
  }

  var configuredObservationTime: UInt64 {
    observationTime
  }
}
#endif

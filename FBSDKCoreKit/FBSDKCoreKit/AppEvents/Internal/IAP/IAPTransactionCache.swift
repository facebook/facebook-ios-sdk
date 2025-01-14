/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import StoreKit

final class IAPTransactionCache: NSObject {
  var configuredDependencies: ObjectDependencies?
  var defaultDependencies: ObjectDependencies? = .init(
    dataStore: UserDefaults.standard
  )

  private var loggedTransactions: Set<IAPCachedTransaction> = []
  private var memoryObserver: NSObjectProtocol?

  static let shared = IAPTransactionCache()

  private override init() {
    super.init()
    loggedTransactions = initializeTransactions()
    observeMemoryWarning()
  }

  deinit {
    if let memoryObserver {
      NotificationCenter.default.removeObserver(memoryObserver)
    }
    memoryObserver = nil
  }
}

// MARK: - Private Methods

extension IAPTransactionCache {
  private func initializeTransactions() -> Set<IAPCachedTransaction> {
    guard let dependencies = try? getDependencies() else {
      return []
    }
    guard let data = dependencies.dataStore.fb_data(forKey: IAPConstants.loggedTransactionsCacheKey) else {
      return []
    }
    guard let transactions = try? JSONDecoder().decode(Set<IAPCachedTransaction>.self, from: data) else {
      return []
    }
    return Set(transactions)
  }

  private func persist() {
    guard let dependencies = try? getDependencies() else {
      return
    }
    guard let data = try? JSONEncoder().encode(loggedTransactions) else {
      return
    }
    dependencies.dataStore.fb_setObject(data, forKey: IAPConstants.loggedTransactionsCacheKey)
  }

  private func observeMemoryWarning() {
    memoryObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.didReceiveMemoryWarningNotification,
      object: nil,
      queue: OperationQueue.main
    ) { _ in
      self.trimIfNeeded(hasLowMemory: true)
    }
  }

  private var oldestCachedTransaction: IAPCachedTransaction? {
    get {
      guard let dependencies = try? getDependencies() else {
        return nil
      }
      guard let data = dependencies.dataStore.fb_data(forKey: IAPConstants.oldestCachedTransactionkey) else {
        return nil
      }
      guard let transaction = try? JSONDecoder().decode(IAPCachedTransaction.self, from: data) else {
        return nil
      }
      return transaction
    }
    set {
      guard let dependencies = try? getDependencies() else {
        return
      }
      guard let data = try? JSONEncoder().encode(newValue) else {
        return
      }
      dependencies.dataStore.fb_setObject(data, forKey: IAPConstants.oldestCachedTransactionkey)
    }
  }
}

// MARK: - Public APIs

extension IAPTransactionCache: _IAPTransactionCaching {

  var hasRestoredPurchases: Bool {
    get {
      guard let dependencies = try? getDependencies() else {
        return false
      }
      return dependencies.dataStore.fb_bool(forKey: IAPConstants.restoredPurchasesCacheKey)
    }
    set {
      guard let dependencies = try? getDependencies() else {
        return
      }
      dependencies.dataStore.fb_setBool(newValue, forKey: IAPConstants.restoredPurchasesCacheKey)
    }
  }

  var newCandidatesDate: Date? {
    get {
      guard let dependencies = try? getDependencies() else {
        return nil
      }
      guard let date =
        dependencies.dataStore.fb_object(forKey: IAPConstants.newCandidatesDateCacheKey) as? Date else {
        return nil
      }
      return date
    }
    set {
      guard let dependencies = try? getDependencies() else {
        return
      }
      guard let newValue else {
        dependencies.dataStore.fb_removeObject(forKey: IAPConstants.newCandidatesDateCacheKey)
        return
      }
      dependencies.dataStore.fb_setObject(newValue, forKey: IAPConstants.newCandidatesDateCacheKey)
    }
  }

  func addTransaction(transactionID: String?, eventName: AppEvents.Name, productID: String) {
    synchronized(self) {
      guard let transactionID else {
        return
      }
      let newTransaction = IAPCachedTransaction(
        transactionID: transactionID,
        productID: productID,
        eventName: eventName.rawValue,
        cachedDate: Date()
      )
      loggedTransactions.insert(newTransaction)
      if newTransaction.isTrimmableTransaction, oldestCachedTransaction == nil {
        oldestCachedTransaction = newTransaction
      }
      persist()
    }
  }

  func removeTransaction(transactionID: String?, eventName: AppEvents.Name, productID: String) {
    synchronized(self) {
      guard let transactionID else {
        return
      }
      let oldTransaction = IAPCachedTransaction(
        transactionID: transactionID,
        productID: productID,
        eventName: eventName.rawValue,
        cachedDate: Date()
      )
      loggedTransactions.remove(oldTransaction)
      persist()
    }
  }

  func contains(transactionID: String?, eventName: AppEvents.Name, productID: String) -> Bool {
    guard let transactionID else {
      return false
    }
    let transactionCandidate = IAPCachedTransaction(
      transactionID: transactionID,
      productID: productID,
      eventName: eventName.rawValue,
      cachedDate: Date()
    )
    return loggedTransactions.contains(transactionCandidate)
  }

  func contains(transactionID: String?, productID: String) -> Bool {
    guard let transactionID else {
      return false
    }
    return loggedTransactions.contains { $0.transactionID == transactionID && $0.productID == productID }
  }

  func trimIfNeeded(hasLowMemory: Bool = false) {
    guard let oldest = oldestCachedTransaction, oldest.cachedDate.isOlderThan30Days() else {
      return
    }
    var updatedOldestTransaction: IAPCachedTransaction?
    let transactions = loggedTransactions
    for transaction in transactions {
      if transaction.isTrimmableTransaction,
         transaction.cachedDate.isOlderThan30Days() || hasLowMemory {
        loggedTransactions.remove(transaction)
      } else if transaction.isTrimmableTransaction,
                transaction.cachedDate < updatedOldestTransaction?.cachedDate ?? Date() {
        updatedOldestTransaction = transaction
      }
    }
    oldestCachedTransaction = updatedOldestTransaction
    persist()
  }
}

// MARK: - IAPCachedTransaction Struct Type

extension IAPTransactionCache {
  struct IAPCachedTransaction: Hashable, Equatable, Codable {
    var transactionID: String
    var productID: String
    var eventName: String
    var cachedDate: Date

    var isTrimmableTransaction: Bool {
      eventName != AppEvents.Name.subscribe.rawValue &&
        eventName != AppEvents.Name.subscribeRestore.rawValue &&
        eventName != AppEvents.Name.startTrial.rawValue
    }

    static func == (lhs: IAPCachedTransaction, rhs: IAPCachedTransaction) -> Bool {
      lhs.transactionID == rhs.transactionID && lhs.eventName == rhs.eventName && lhs.productID == rhs.productID
    }

    func hash(into hasher: inout Hasher) {
      hasher.combine(transactionID)
      hasher.combine(eventName)
      hasher.combine(productID)
    }
  }
}

// MARK: - DependentAsObject

extension IAPTransactionCache: DependentAsObject {
  struct ObjectDependencies {
    var dataStore: DataPersisting
  }
}

extension Date {
  func isOlderThan30Days() -> Bool {
    let calendar = Calendar.current
    guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) else {
      return false
    }
    return self < thirtyDaysAgo
  }
}

// MARK: - Testing

#if DEBUG
extension IAPTransactionCache {
  func reset() {
    UserDefaults.standard.removeObject(forKey: IAPConstants.restoredPurchasesCacheKey)
    UserDefaults.standard.removeObject(forKey: IAPConstants.loggedTransactionsCacheKey)
    UserDefaults.standard.removeObject(forKey: IAPConstants.newCandidatesDateCacheKey)
    UserDefaults.standard.removeObject(forKey: IAPConstants.oldestCachedTransactionkey)
    configuredDependencies = nil
    loggedTransactions = []
  }

  func getPersistedTransactions() -> Set<IAPCachedTransaction> {
    let transactions = initializeTransactions()
    return transactions
  }

  func getLoggedTransactions() -> Set<IAPCachedTransaction> {
    let transactions = loggedTransactions
    return transactions
  }

  func addPersistedTransaction(transaction: IAPCachedTransaction) {
    if transaction.isTrimmableTransaction, oldestCachedTransaction == nil {
      oldestCachedTransaction = transaction
    }
    loggedTransactions.insert(transaction)
    persist()
  }

  var oldestCachedTransactionForTests: IAPCachedTransaction? {
    oldestCachedTransaction
  }
}
#endif

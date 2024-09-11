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
  static let restoredPurchasesKey = "com.facebook.sdk:RestoredPurchasesKey"
  static let loggedTransactionsKey = "com.facebook.sdk:LoggedTransactionsKey"
  static let newCandidatesDateKey = "com.facebook.sdk:NewCandidatesDateKey"

  var configuredDependencies: ObjectDependencies?
  var defaultDependencies: ObjectDependencies? = .init(
    dataStore: UserDefaults.standard
  )

  private var loggedTransactions: Set<IAPCachedTransaction> = []

  static let shared = IAPTransactionCache()

  private override init() {
    super.init()
    loggedTransactions = initializeTransactions()
  }
}

// MARK: - Private Methods

extension IAPTransactionCache {
  private func initializeTransactions() -> Set<IAPCachedTransaction> {
    guard let dependencies = try? getDependencies() else {
      return []
    }
    guard let data = dependencies.dataStore.fb_data(forKey: IAPTransactionCache.loggedTransactionsKey) else {
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
    dependencies.dataStore.fb_setObject(data, forKey: IAPTransactionCache.loggedTransactionsKey)
  }
}

// MARK: - Public APIs

extension IAPTransactionCache {
  var hasRestoredPurchases: Bool {
    // swiftlint:disable:next implicit_getter
    get {
      guard let dependencies = try? getDependencies() else {
        return false
      }
      return dependencies.dataStore.fb_bool(forKey: IAPTransactionCache.restoredPurchasesKey)
    }
    set {
      guard let dependencies = try? getDependencies() else {
        return
      }
      dependencies.dataStore.fb_setBool(newValue, forKey: IAPTransactionCache.restoredPurchasesKey)
    }
  }

  var newCandidatesDate: Date? {
    // swiftlint:disable:next implicit_getter
    get {
      guard let dependencies = try? getDependencies() else {
        return nil
      }
      guard let date =
        dependencies.dataStore.fb_object(forKey: IAPTransactionCache.newCandidatesDateKey) as? Date else {
        return nil
      }
      return date
    }
    set {
      guard let dependencies = try? getDependencies() else {
        return
      }
      guard let newValue else {
        return
      }
      dependencies.dataStore.fb_setObject(newValue, forKey: IAPTransactionCache.newCandidatesDateKey)
    }
  }

  func addTransaction(transactionID: UInt64, eventName: AppEvents.Name) {
    synchronized(self) {
      let newTransaction = IAPCachedTransaction(transactionID: transactionID, eventName: eventName.rawValue)
      loggedTransactions.insert(newTransaction)
      persist()
    }
  }

  func removeTransaction(transactionID: UInt64, eventName: AppEvents.Name) {
    synchronized(self) {
      let oldTransaction = IAPCachedTransaction(transactionID: transactionID, eventName: eventName.rawValue)
      loggedTransactions.remove(oldTransaction)
      persist()
    }
  }

  func contains(transactionID: UInt64, eventName: AppEvents.Name) -> Bool {
    let transactionCandidate = IAPCachedTransaction(transactionID: transactionID, eventName: eventName.rawValue)
    return loggedTransactions.contains(transactionCandidate)
  }

  func contains(transactionID: UInt64) -> Bool {
    return loggedTransactions.contains { $0.transactionID == transactionID } // swiftlint:disable:this implicit_return
  }
}

// MARK: - IAPCachedTransaction Struct Type

extension IAPTransactionCache {
  struct IAPCachedTransaction: Hashable, Equatable, Codable {
    var transactionID: UInt64
    var eventName: String
  }
}

// MARK: - DependentAsObject

extension IAPTransactionCache: DependentAsObject {
  struct ObjectDependencies {
    var dataStore: DataPersisting
  }
}

// MARK: - Testing

#if DEBUG
extension IAPTransactionCache {
  func reset() {
    UserDefaults.standard.removeObject(forKey: IAPTransactionCache.restoredPurchasesKey)
    UserDefaults.standard.removeObject(forKey: IAPTransactionCache.loggedTransactionsKey)
    UserDefaults.standard.removeObject(forKey: IAPTransactionCache.newCandidatesDateKey)
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
}
#endif

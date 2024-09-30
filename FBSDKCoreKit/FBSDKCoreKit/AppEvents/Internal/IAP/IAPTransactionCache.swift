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
}

// MARK: - Public APIs

extension IAPTransactionCache {
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
        return
      }
      dependencies.dataStore.fb_setObject(newValue, forKey: IAPConstants.newCandidatesDateCacheKey)
    }
  }

  func addTransaction(transactionID: String?, eventName: AppEvents.Name) {
    synchronized(self) {
      guard let transactionID else {
        return
      }
      let newTransaction = IAPCachedTransaction(transactionID: transactionID, eventName: eventName.rawValue)
      loggedTransactions.insert(newTransaction)
      persist()
    }
  }

  func removeTransaction(transactionID: String?, eventName: AppEvents.Name) {
    synchronized(self) {
      guard let transactionID else {
        return
      }
      let oldTransaction = IAPCachedTransaction(transactionID: transactionID, eventName: eventName.rawValue)
      loggedTransactions.remove(oldTransaction)
      persist()
    }
  }

  func contains(transactionID: String?, eventName: AppEvents.Name) -> Bool {
    guard let transactionID else {
      return false
    }
    let transactionCandidate = IAPCachedTransaction(transactionID: transactionID, eventName: eventName.rawValue)
    return loggedTransactions.contains(transactionCandidate)
  }

  func contains(transactionID: String?) -> Bool {
    guard let transactionID else {
      return false
    }
    return loggedTransactions.contains { $0.transactionID == transactionID }
  }
}

// MARK: - IAPCachedTransaction Struct Type

extension IAPTransactionCache {
  struct IAPCachedTransaction: Hashable, Equatable, Codable {
    var transactionID: String
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
    UserDefaults.standard.removeObject(forKey: IAPConstants.restoredPurchasesCacheKey)
    UserDefaults.standard.removeObject(forKey: IAPConstants.loggedTransactionsCacheKey)
    UserDefaults.standard.removeObject(forKey: IAPConstants.newCandidatesDateCacheKey)
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

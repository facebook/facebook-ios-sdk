// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation
import StoreKit

enum SK2PurchaseResult {
  case success
  case pending
  case failed
}

@available(iOS 15.0, *)
protocol SK2StoreManagerUpdatesDelegate: AnyObject {
  func didReceiveUpdatedTransactions() async
  func didFailToRestoreTransactions() async
  func didRestoreTransactions() async
}

@available(iOS 15.0, *)
final class SK2StoreManager: NSObject {
  static let shared = SK2StoreManager()

  weak var delegate: SK2StoreManagerUpdatesDelegate?
  private(set) var purchases = [Transaction]()
  var updateListenerTask: Task<Void, Error>?

  private override init() {
    super.init()
    updateListenerTask = listenForTransactionUpdates()
  }

  deinit {
    updateListenerTask?.cancel()
  }
}

// MARK: - Fetch Products

@available(iOS 15.0, *)
extension SK2StoreManager {
  func fetchProducts(productIdentifiers: [String] = ProductIdentifiers.allIdentifiers) async -> [Product] {
    guard let products = try? await Product.products(for: productIdentifiers) else {
      return []
    }
    return products
  }
}

// MARK: - Purchases

@available(iOS 15.0, *)
extension SK2StoreManager {
  func buy(product: Product) async -> SK2PurchaseResult {
    guard let purchaseResult = try? await product.purchase() else {
      return .failed
    }
    switch purchaseResult {
    case let .success(verificationResult):
      switch verificationResult {
      case .unverified:
        return .failed
      case let .verified(transaction):
        await transaction.finish()
        purchases.append(transaction)
        return .success
      }
    case .userCancelled: return .failed
    case .pending: return .pending
    default: return .failed
    }
  }

  func fetchPurchases() async {
    let currentIDs = purchases.map {
      $0.id
    }
    for await verificationResult in Transaction.currentEntitlements {
      switch verificationResult {
      case let .verified(transaction):
        if !currentIDs.contains(transaction.originalID) {
          purchases.append(transaction)
        }
      case .unverified:
        continue
      }
    }
  }

  func restorePurchases() async {
    do {
      try await AppStore.sync()
      await fetchPurchases()
      await delegate?.didRestoreTransactions()
    } catch {
      await delegate?.didFailToRestoreTransactions()
    }
  }

  private func listenForTransactionUpdates() -> Task<Void, Error> {
    return Task.detached {
      for await verificationResult in Transaction.updates {
        switch verificationResult {
        case .unverified: continue
        case let .verified(transaction):
          await transaction.finish()
          self.purchases.append(transaction)
          await self.delegate?.didReceiveUpdatedTransactions()
        }
      }
    }
  }
}

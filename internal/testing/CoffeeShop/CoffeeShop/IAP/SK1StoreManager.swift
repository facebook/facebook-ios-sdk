// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation
import StoreKit

protocol SK1StoreManagerProductFetchingDelegate: AnyObject {
  func didFetchProducts(_ products: [SKProduct])
}

protocol SK1StoreManagerProductPurchasingDelegate: AnyObject {
  func purchaseDidSucceed(_ transaction: SKPaymentTransaction)
  func purchaseDidFail(_ transaction: SKPaymentTransaction)
  func restoreDidFail(withError: Error)
  func notifyRestoreDidSucceed()
  func notifyNoRestoredPurchases()
}

final class SK1StoreManager: NSObject {
  static let shared = SK1StoreManager()
  private override init() {}

  weak var productFetchingDelegate: SK1StoreManagerProductFetchingDelegate?
  weak var productPurchasingDelegate: SK1StoreManagerProductPurchasingDelegate?
  private(set) var purchases = [SKPaymentTransaction]()
  private(set) var restored = [SKPaymentTransaction]()
  private var availableProducts = [String: SKProduct]()
}

// MARK: - Fetch the Products

extension SK1StoreManager: SKProductsRequestDelegate {
  func fetchProducts(productIdentifiers: [String] = ProductIdentifiers.allIdentifiers) {
    let request = SKProductsRequest(productIdentifiers: Set(productIdentifiers))
    request.delegate = self
    request.start()
  }

  func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
    availableProducts = [:]
    let products = response.products
    for product in products {
      availableProducts[product.productIdentifier] = product
    }
    DispatchQueue.main.async {
      self.productFetchingDelegate?.didFetchProducts(products)
    }
  }

  func request(_ request: SKRequest, didFailWithError error: Error) {
    availableProducts = [:]
    DispatchQueue.main.async {
      self.productFetchingDelegate?.didFetchProducts([])
    }
  }

  func getProductFor(productID: String?) -> SKProduct? {
    guard let productID else {
      return nil
    }
    return availableProducts[productID]
  }
}

// MARK: - Buy the products

extension SK1StoreManager: SKPaymentTransactionObserver {
  private func handlePurchased(transaction: SKPaymentTransaction) {
    purchases.append(transaction)
    DispatchQueue.main.async {
      self.productPurchasingDelegate?.purchaseDidSucceed(transaction)
    }
    SKPaymentQueue.default().finishTransaction(transaction)
  }

  private func handleRestored(transaction: SKPaymentTransaction) {
    restored.append(transaction)
    SKPaymentQueue.default().finishTransaction(transaction)
  }

  private func handleFailed(transaction: SKPaymentTransaction) {
    DispatchQueue.main.async {
      self.productPurchasingDelegate?.purchaseDidFail(transaction)
    }
    SKPaymentQueue.default().finishTransaction(transaction)
  }

  func buy(product: SKProduct) {
    let payment = SKMutablePayment(product: product)
    SKPaymentQueue.default().add(payment)
  }

  func restorePurchases() {
    if !restored.isEmpty {
      restored.removeAll()
    }
    SKPaymentQueue.default().restoreCompletedTransactions()
  }

  func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    for transaction in transactions {
      switch transaction.transactionState {
      case .purchasing: break
      case .purchased: handlePurchased(transaction: transaction)
      case .failed: handleFailed(transaction: transaction)
      case .restored: handleRestored(transaction: transaction)
      case .deferred: break
      @unknown default: break
      }
    }
  }

  func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
    DispatchQueue.main.async {
      self.productPurchasingDelegate?.restoreDidFail(withError: error)
    }
  }

  func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
    DispatchQueue.main.async {
      if self.restored.isEmpty {
        self.productPurchasingDelegate?.notifyNoRestoredPurchases()
      } else {
        self.productPurchasingDelegate?.notifyRestoreDidSucceed()
      }
    }
  }
}

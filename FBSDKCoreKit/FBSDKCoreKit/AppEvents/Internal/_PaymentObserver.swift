/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import StoreKit

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE

 Class to encapsulate implicit logging of purchase events
 */
@objc(FBSDKPaymentObserver)
public final class _PaymentObserver: NSObject, _PaymentObserving {
  var isObservingTransactions = false
  let paymentQueue: SKPaymentQueue
  let requestorFactory: _PaymentProductRequestorCreating

  @objc(initWithPaymentQueue:paymentProductRequestorFactory:)
  public init(paymentQueue: SKPaymentQueue, paymentProductRequestorFactory: _PaymentProductRequestorCreating) {
    self.paymentQueue = paymentQueue
    requestorFactory = paymentProductRequestorFactory
    super.init()
  }

  @objc(startObservingTransactions)
  public func startObservingTransactions() {
    synchronized(self) {
      if !isObservingTransactions {
        paymentQueue.add(self)
        isObservingTransactions = true
      }
    }
  }

  @objc(stopObservingTransactions)
  public func stopObservingTransactions() {
    synchronized(self) {
      if isObservingTransactions {
        paymentQueue.remove(self)
        isObservingTransactions = false
      }
    }
  }
}

extension _PaymentObserver: SKPaymentTransactionObserver {

  public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
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

  func handleTransaction(_ transaction: SKPaymentTransaction) {
    let productRequestor = requestorFactory.createRequestor(transaction: transaction)
    productRequestor.resolveProducts()
  }
}

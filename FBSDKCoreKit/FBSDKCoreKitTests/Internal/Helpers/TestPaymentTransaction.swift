/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@available(iOS 12.2, *)
class TestPaymentTransaction: SKPaymentTransaction {
  private let stubbedTransactionIdentifier: String?
  private let stubbedTransactionState: SKPaymentTransactionState
  private let stubbedTransactionDate: Date?
  private let stubbedPayment: TestPayment
  private let stubbedOriginalTransaction: TestPaymentTransaction?

  init(
    identifier: String? = nil,
    state: SKPaymentTransactionState,
    date: Date? = nil,
    payment: TestPayment = TestPayment(productIdentifier: UUID().uuidString),
    originalTransaction: TestPaymentTransaction? = nil
  ) {
    stubbedTransactionIdentifier = identifier
    stubbedTransactionState = state
    stubbedTransactionDate = date
    stubbedPayment = payment
    stubbedOriginalTransaction = originalTransaction

    super.init()
  }

  override var original: SKPaymentTransaction? {
    stubbedOriginalTransaction
  }

  override var transactionIdentifier: String? {
    stubbedTransactionIdentifier
  }

  override var transactionState: SKPaymentTransactionState {
    stubbedTransactionState
  }

  override var transactionDate: Date? {
    stubbedTransactionDate
  }

  override var payment: SKPayment {
    stubbedPayment
  }
}

/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import StoreKit

@available(iOS 12.2, *)
public final class TestPaymentTransaction: SKPaymentTransaction {
  private let stubbedTransactionIdentifier: String?
  private let stubbedTransactionState: SKPaymentTransactionState
  private let stubbedTransactionDate: Date?
  private let stubbedPayment: TestPayment
  private let stubbedOriginalTransaction: TestPaymentTransaction?

  public init(
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

  public override var original: SKPaymentTransaction? {
    stubbedOriginalTransaction
  }

  public override var transactionIdentifier: String? {
    stubbedTransactionIdentifier
  }

  public override var transactionState: SKPaymentTransactionState {
    stubbedTransactionState
  }

  public override var transactionDate: Date? {
    stubbedTransactionDate
  }

  public override var payment: SKPayment {
    stubbedPayment
  }
}

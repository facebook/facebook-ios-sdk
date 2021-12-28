/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

@available(iOS 12.2, *)
class PaymentObserverTests: XCTestCase {

  lazy var observer = PaymentObserver(
    paymentQueue: queue,
    paymentProductRequestorFactory: requestorFactory
  )
  let queue = TestPaymentQueue()
  let requestorFactory = TestPaymentProductRequestorFactory()

  // MARK: - Dependencies

  func testCreatingWithCustomDependencies() {
    XCTAssertEqual(
      observer.paymentQueue,
      queue,
      "Should use the provided payment queue"
    )
    XCTAssertTrue(
      observer.requestorFactory === requestorFactory,
      "Should use the provided payment product requestor factory"
    )
  }

  // MARK: - Observing Transactions

  func testStartingObservanceWhenNotObserving() {
    observer.startObservingTransactions()
    XCTAssertTrue(
      queue.addTransactionObserverWasCalled,
      "Should add the observer to the queue when not observing"
    )
  }

  func testStartingObservanceWhenObserving() {
    observer.startObservingTransactions()
    queue.addTransactionObserverWasCalled = false
    observer.startObservingTransactions()

    XCTAssertFalse(
      queue.addTransactionObserverWasCalled,
      "Should not add the observer to the queue when observing"
    )
  }

  func testStoppingObservanceWhenNotObserving() {
    observer.stopObservingTransactions()

    XCTAssertFalse(
      queue.removeTransactionObserverWasCalled,
      "Should not remove an observer from a queue when not observing"
    )
  }

  func testStoppingObservanceWhenObserving() {
    observer.startObservingTransactions()
    observer.stopObservingTransactions()

    XCTAssertTrue(
      queue.removeTransactionObserverWasCalled,
      "Should remove an observer from a queue when observing"
    )
  }

  func testHandlingUpdatedTransactions() {
    let purchasing = TestPaymentTransaction(state: .purchasing)
    let purchased = TestPaymentTransaction(state: .purchased)
    let failed = TestPaymentTransaction(state: .failed)
    let restored = TestPaymentTransaction(state: .restored)
    let deferred = TestPaymentTransaction(state: .deferred)

    let transactions = [
      purchasing,
      purchased,
      failed,
      restored,
      deferred
    ]
    observer.paymentQueue(queue, updatedTransactions: transactions)

    XCTAssertEqual(
      requestorFactory.evidence.map(\.transaction),
      [purchasing, purchased, failed, restored]
    )
    XCTAssertTrue(
      requestorFactory.evidence
        .map(\.requestor)
        .map(\.wasResolveProductsCalled)
        .allSatisfy { $0 }
    )
  }
}

// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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

  func testCreatingWithDefaults() {
    observer = PaymentObserver.shared

    XCTAssertEqual(
      observer.paymentQueue,
      SKPaymentQueue.default(),
      "Should use the expected concrete payment queue by default"
    )
    XCTAssertTrue(
      observer.requestorFactory is PaymentProductRequestorFactory,
      "Should use the expected concrete payment product requestor factory by default"
    )
  }

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

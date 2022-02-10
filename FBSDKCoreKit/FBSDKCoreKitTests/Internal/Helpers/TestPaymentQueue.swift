/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

final class TestPaymentQueue: SKPaymentQueue {

  var addTransactionObserverWasCalled = false
  var removeTransactionObserverWasCalled = false

  override func add(_ observer: SKPaymentTransactionObserver) {
    addTransactionObserverWasCalled = true
  }

  override func remove(_ observer: SKPaymentTransactionObserver) {
    removeTransactionObserverWasCalled = true
  }
}

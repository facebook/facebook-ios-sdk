/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import StoreKit

public final class TestPaymentQueue: SKPaymentQueue {

  public var addTransactionObserverWasCalled = false
  public var removeTransactionObserverWasCalled = false

  public override func add(_ observer: SKPaymentTransactionObserver) {
    addTransactionObserverWasCalled = true
  }

  public override func remove(_ observer: SKPaymentTransactionObserver) {
    removeTransactionObserverWasCalled = true
  }
}

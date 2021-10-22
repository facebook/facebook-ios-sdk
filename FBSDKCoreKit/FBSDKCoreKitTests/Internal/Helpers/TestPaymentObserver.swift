/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@objcMembers
class TestPaymentObserver: NSObject, PaymentObserving {
  var didStartObservingTransactions = false
  var didStopObservingTransactions = false

  func startTransactions() {
    didStartObservingTransactions = true
  }

  func stopTransactions() {
    didStopObservingTransactions = true
  }
}

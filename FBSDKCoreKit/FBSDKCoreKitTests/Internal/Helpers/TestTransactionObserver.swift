/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objcMembers
final class TestTransactionObserver: NSObject, _TransactionObserving {
  var didStartObserving = false
  var didStopObserving = false

  func startObserving() {
    didStartObserving = true
  }

  func stopObserving() {
    didStopObserving = true
  }
}

/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objcMembers
final class TestOperationQueue: OperationQueue {

  var addOperationWithBlockWasCalled = false
  var capturedOperationBlock: (() -> Void)?

  override func addOperation(_ block: @escaping () -> Void) {
    addOperationWithBlockWasCalled = true
    capturedOperationBlock = block
  }
}

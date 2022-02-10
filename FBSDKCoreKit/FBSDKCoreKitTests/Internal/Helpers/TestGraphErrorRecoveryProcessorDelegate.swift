/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

final class TestGraphErrorRecoveryProcessorDelegate: NSObject, GraphErrorRecoveryProcessorDelegate {

  var wasRecoveryAttempted = false
  var capturedProcessor: GraphErrorRecoveryProcessor?
  var capturedDidRecover = false
  var capturedError: NSError?

  func processorDidAttemptRecovery(
    _ processor: GraphErrorRecoveryProcessor,
    didRecover: Bool,
    error: Error?
  ) {
    wasRecoveryAttempted = true
    capturedProcessor = processor
    capturedDidRecover = didRecover
    capturedError = error as NSError?
  }
}

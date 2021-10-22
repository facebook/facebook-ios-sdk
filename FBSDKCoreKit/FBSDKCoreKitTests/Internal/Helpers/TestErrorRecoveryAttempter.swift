/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

class TestErrorRecoveryAttempter: NSObject, ErrorRecoveryAttempting {

  var capturedError: Error?
  var capturedOptionIndex: UInt?
  var capturedCompletion: ((Bool) -> Void)?

  func attemptRecovery(
    fromError error: Error,
    optionIndex recoveryOptionIndex: UInt,
    completionHandler: @escaping (Bool) -> Void
  ) {
    capturedError = error
    capturedOptionIndex = recoveryOptionIndex
    capturedCompletion = completionHandler
  }
}

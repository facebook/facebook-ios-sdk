/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

class TestErrorRecoveryAttempter: NSObject, ErrorRecoveryAttempting {
  var capturedError: Error?
  var capturedCompletion: ((Bool) -> Void)?

  func attemptRecovery(
    fromError error: Error,
    completionHandler: @escaping (Bool) -> Void
  ) {
    capturedError = error
    capturedCompletion = completionHandler
  }
}

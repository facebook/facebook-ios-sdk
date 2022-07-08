/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

final class TestErrorRecoveryAttempter: ErrorRecoveryAttempting {
  var capturedError: Error?
  var capturedCompletion: ((Bool) -> Void)?

  func attemptRecovery(
    from error: Error,
    completion: @escaping (Bool) -> Void
  ) {
    capturedError = error
    capturedCompletion = completion
  }
}

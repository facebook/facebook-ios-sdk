/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

class TestLoggingNotifier: LoggingNotifying {
  var capturedMessage: String?

  func logAndNotify(_ message: String) {
    capturedMessage = message
  }

  func logAndNotify(_ message: String, allowLogAsDeveloperError: Bool) {
    XCTFail("Message should be captured and asserted against")
  }
}

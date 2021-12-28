/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import XCTest

@objcMembers
class TestLogger: NSObject, Logging {
  var contents = ""

  var loggingBehavior: LoggingBehavior

  required init(loggingBehavior: LoggingBehavior) {
    self.loggingBehavior = loggingBehavior
  }

  static func singleShotLogEntry(_ loggingBehavior: LoggingBehavior, logEntry: String) {}

  func logEntry(_ logEntry: String) {}
}

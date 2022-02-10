/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objcMembers
final class TestLoggerFactory: NSObject, LoggerCreating {
  var capturedLoggingBehavior: LoggingBehavior?
  var logger = TestLogger(loggingBehavior: .developerErrors)

  func createLogger(withLoggingBehavior loggingBehavior: LoggingBehavior) -> Logging {
    capturedLoggingBehavior = loggingBehavior
    return logger
  }
}

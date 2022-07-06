/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit

import FBSDKCoreKit

final class TestLogger: GamingLogging {
  var contents = ""
  var loggingBehavior: LoggingBehavior

  init(loggingBehavior: LoggingBehavior) {
    self.loggingBehavior = loggingBehavior
  }

  static func singleShotLogEntry(_ loggingBehavior: LoggingBehavior, logEntry: String) {}

  func logEntry(_ logEntry: String) {}

  static func reset() {}
}

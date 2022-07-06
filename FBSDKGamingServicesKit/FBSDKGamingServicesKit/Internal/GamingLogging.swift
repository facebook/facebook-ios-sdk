/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

protocol GamingLogging {
  static func singleShotLogEntry(
    _ loggingBehavior: LoggingBehavior,
    logEntry: String
  )
}

extension Logger: GamingLogging {}

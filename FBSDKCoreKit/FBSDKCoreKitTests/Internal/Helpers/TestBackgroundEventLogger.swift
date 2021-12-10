/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@objcMembers
class TestBackgroundEventLogger: NSObject, BackgroundEventLogging {

  required init(
    infoDictionaryProvider: InfoDictionaryProviding,
    eventLogger: EventLogging
  ) {
  }

  var logBackgroundRefresStatusCallCount = 0

  func logBackgroundRefreshStatus(_ status: UIBackgroundRefreshStatus) {
    logBackgroundRefresStatusCallCount += 1
  }
}

/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import Foundation

final class TestBackgroundEventLogger: NSObject, _BackgroundEventLogging {

  var logBackgroundRefresStatusCallCount = 0

  func logBackgroundRefreshStatus(_ status: UIBackgroundRefreshStatus) {
    logBackgroundRefresStatusCallCount += 1
  }
}

extension TestBackgroundEventLogger: DependentAsType {
  struct TypeDependencies {
    var infoDictionaryProvider: InfoDictionaryProviding
    var eventLogger: EventLogging
  }

  static var configuredDependencies: TypeDependencies?

  static var defaultDependencies: TypeDependencies? = TypeDependencies(
    infoDictionaryProvider: TestBundle(),
    eventLogger: TestEventLogger()
  )
}

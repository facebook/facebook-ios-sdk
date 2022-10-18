/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objcMembers
final class TestAppEventsConfigurationProvider: NSObject, _AppEventsConfigurationProviding {
  var stubbedConfiguration: _AppEventsConfigurationProtocol?
  var didRetrieveCachedConfiguration = false
  var firstCapturedBlock: _AppEventsConfigurationProvidingBlock?
  var lastCapturedBlock: _AppEventsConfigurationProvidingBlock?

  var cachedAppEventsConfiguration: _AppEventsConfigurationProtocol {
    guard let configuration = stubbedConfiguration else {
      fatalError("A cached configuration is required")
    }
    didRetrieveCachedConfiguration = true
    return configuration
  }

  func loadAppEventsConfiguration(_ block: @escaping _AppEventsConfigurationProvidingBlock) {
    if firstCapturedBlock == nil {
      firstCapturedBlock = block
    }
    lastCapturedBlock = block
  }
}

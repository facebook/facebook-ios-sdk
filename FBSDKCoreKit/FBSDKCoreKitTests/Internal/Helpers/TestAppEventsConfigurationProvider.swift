/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@objcMembers
class TestAppEventsConfigurationProvider: NSObject, AppEventsConfigurationProviding {
  var stubbedConfiguration: AppEventsConfigurationProtocol?
  var didRetrieveCachedConfiguration = false
  var firstCapturedBlock: AppEventsConfigurationProvidingBlock?
  var lastCapturedBlock: AppEventsConfigurationProvidingBlock?

  var cachedAppEventsConfiguration: AppEventsConfigurationProtocol {
    guard let configuration = stubbedConfiguration else {
      fatalError("A cached configuration is required")
    }
    didRetrieveCachedConfiguration = true
    return configuration
  }

  func loadAppEventsConfiguration(_ block: @escaping AppEventsConfigurationProvidingBlock) {
    if firstCapturedBlock == nil {
      firstCapturedBlock = block
    }
    lastCapturedBlock = block
  }
}

/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@objcMembers
class TestAppEventsConfigurationProvider: NSObject, AppEventsConfigurationProviding {
  static var stubbedConfiguration: AppEventsConfigurationProtocol?
  static var didRetrieveCachedConfiguration = false
  static var capturedBlock: AppEventsConfigurationProvidingBlock?
  static var lastCapturedBlock: AppEventsConfigurationProvidingBlock?

  var capturedBlock: AppEventsConfigurationProvidingBlock?
  var lastCapturedBlock: AppEventsConfigurationProvidingBlock?

  static func cachedAppEventsConfiguration() -> AppEventsConfigurationProtocol {
    guard let configuration = stubbedConfiguration else {
      fatalError("A cached configuration is required")
    }
    didRetrieveCachedConfiguration = true
    return configuration
  }

  static func reset() {
    stubbedConfiguration = nil
    didRetrieveCachedConfiguration = false
    capturedBlock = nil
    lastCapturedBlock = nil
  }

  static func loadAppEventsConfiguration(_ block: @escaping AppEventsConfigurationProvidingBlock) {
    guard capturedBlock == nil else {
      lastCapturedBlock = block
      return
    }

    capturedBlock = block
  }

  func loadAppEventsConfiguration(_ block: @escaping AppEventsConfigurationProvidingBlock) {
    guard capturedBlock == nil else {
      lastCapturedBlock = block
      return
    }

    capturedBlock = block
  }
}

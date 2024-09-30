/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

@objcMembers
public final class TestAppEventsConfigurationProvider: NSObject, _AppEventsConfigurationProviding {
  public var stubbedConfiguration: _AppEventsConfigurationProtocol?
  public var didRetrieveCachedConfiguration = false
  public var firstCapturedBlock: _AppEventsConfigurationProvidingBlock?
  public var lastCapturedBlock: _AppEventsConfigurationProvidingBlock?

  public var cachedAppEventsConfiguration: _AppEventsConfigurationProtocol {
    guard let configuration = stubbedConfiguration else {
      fatalError("A cached configuration is required")
    }
    didRetrieveCachedConfiguration = true
    return configuration
  }

  public func loadAppEventsConfiguration(_ block: @escaping _AppEventsConfigurationProvidingBlock) {
    if firstCapturedBlock == nil {
      firstCapturedBlock = block
    }
    lastCapturedBlock = block
  }
}

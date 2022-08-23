/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import TestTools

@objcMembers
final class TestServerConfigurationProvider: NSObject, _ServerConfigurationProviding {

  var capturedCompletionBlock: _ServerConfigurationBlock?
  var secondCapturedCompletionBlock: _ServerConfigurationBlock?
  var loadServerConfigurationWasCalled = false
  var stubbedRequestToLoadServerConfiguration: GraphRequest?
  var stubbedServerConfiguration: _ServerConfiguration
  var requestToLoadConfigurationCallWasCalled = false
  var didRetrieveCachedServerConfiguration = false

  init(configuration: _ServerConfiguration = ServerConfigurationFixtures.defaultConfiguration) {
    stubbedServerConfiguration = configuration
  }

  func cachedServerConfiguration() -> _ServerConfiguration {
    didRetrieveCachedServerConfiguration = true
    return stubbedServerConfiguration
  }

  func loadServerConfiguration(completionBlock: _ServerConfigurationBlock?) {
    loadServerConfigurationWasCalled = true
    guard capturedCompletionBlock == nil else {
      secondCapturedCompletionBlock = completionBlock
      return
    }

    capturedCompletionBlock = completionBlock
  }

  func reset() {
    requestToLoadConfigurationCallWasCalled = false
    loadServerConfigurationWasCalled = false
    capturedCompletionBlock = nil
    secondCapturedCompletionBlock = nil
  }

  func processLoadRequestResponse(_ result: Any, error: Error?, appID: String) {}

  func request(toLoadServerConfiguration appID: String) -> GraphRequest? {
    requestToLoadConfigurationCallWasCalled = true
    return stubbedRequestToLoadServerConfiguration
  }
}

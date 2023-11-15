/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

final class TestAppEventsServerConfigurationProvider: NSObject, _ServerConfigurationProviding {
  var configs: [String: Any]?

  func cachedServerConfiguration() -> _ServerConfiguration {
    if let configs = configs {
      return ServerConfigurationFixtures.configuration(withDictionary: configs)
    } else {
      return ServerConfigurationFixtures.defaultConfiguration
    }
  }

  func loadServerConfiguration(completionBlock: _ServerConfigurationBlock? = nil) {
    // no-op
  }

  func processLoadRequestResponse(_ result: Any, error: Error?, appID: String) {
    // no-op
  }

  func request(toLoadServerConfiguration appID: String) -> GraphRequest? {
    // no-op
    return nil
  }
}

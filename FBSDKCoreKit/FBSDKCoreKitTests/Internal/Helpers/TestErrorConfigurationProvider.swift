/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objcMembers
final class TestErrorConfigurationProvider: NSObject, _ErrorConfigurationProviding {
  var configuration: _ErrorConfigurationProtocol?

  init(configuration: _ErrorConfigurationProtocol? = nil) {
    self.configuration = configuration
  }

  func errorConfiguration() -> _ErrorConfigurationProtocol? {
    configuration
  }
}

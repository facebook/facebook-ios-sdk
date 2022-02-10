/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objcMembers
final class TestErrorConfigurationProvider: NSObject, ErrorConfigurationProviding {
  var configuration: ErrorConfigurationProtocol?

  init(configuration: ErrorConfigurationProtocol? = nil) {
    self.configuration = configuration
  }

  func errorConfiguration() -> ErrorConfigurationProtocol? {
    configuration
  }
}

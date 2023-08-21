/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit

final class TestServerConfigurationProvider: ServerConfigurationProviding {
  var capturedCompletion: LoginTooltipBlock?

  func loadServerConfiguration(completion: LoginTooltipBlock?) {
    capturedCompletion = completion
  }
}

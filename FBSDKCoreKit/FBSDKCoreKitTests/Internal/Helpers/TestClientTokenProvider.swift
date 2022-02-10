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
final class TestClientTokenProvider: NSObject, ClientTokenProviding {
  var clientToken: String?

  init(clientToken: String? = nil) {
    self.clientToken = clientToken
  }
}

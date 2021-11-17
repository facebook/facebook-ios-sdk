/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

class TestImpressionLogger: ImpressionLogging {

  var capturedIdentifier: String?
  var capturedParameters: [String: Any]?

  func logImpression(
    withIdentifier identifier: String,
    parameters: [String: Any]?
  ) {
    capturedIdentifier = identifier
    capturedParameters = parameters
  }
}

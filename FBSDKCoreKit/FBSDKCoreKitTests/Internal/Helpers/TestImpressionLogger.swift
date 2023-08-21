/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

final class TestImpressionLogger: ImpressionLogging {

  var capturedIdentifier: String?
  var capturedParameters: [AppEvents.ParameterName: Any]?

  func logImpression(
    withIdentifier identifier: String,
    parameters: [AppEvents.ParameterName: Any]?
  ) {
    capturedIdentifier = identifier
    capturedParameters = parameters
  }
}

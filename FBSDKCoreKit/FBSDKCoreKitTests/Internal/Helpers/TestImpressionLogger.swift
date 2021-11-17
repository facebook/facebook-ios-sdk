/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

class TestImpressionLogger: ImpressionLogging {

  func logImpression( // swiftlint:disable:this unavailable_function
    withIdentifier identifier: String,
    parameters: [String: Any]?
  ) {
    fatalError("Log impression not implemented")
  }
}

/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import XCTest

class TestFeatureExtractor: FeatureExtracting {
  static var stubbedDenseFeatures: UnsafeMutablePointer<Float>?

  static func stub(denseFeatures: UnsafeMutablePointer<Float>) {
    stubbedDenseFeatures = denseFeatures
  }

  static func getDenseFeatures(_ viewHierarchy: [String: Any]) -> UnsafeMutablePointer<Float>? {
    stubbedDenseFeatures
  }

  static func reset() {
    stubbedDenseFeatures = nil
  }
}

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
  static var capturedGetTextFeatureText: String?
  static var capturedGetTextFeatureScreenName: String?

  static func stub(denseFeatures: UnsafeMutablePointer<Float>) {
    stubbedDenseFeatures = denseFeatures
  }

  static func getDenseFeatures(_ viewHierarchy: [String: Any]) -> UnsafeMutablePointer<Float>? {
    stubbedDenseFeatures
  }

  static func getTextFeature(_ text: String, withScreenName screenName: String) -> String {
    capturedGetTextFeatureText = text
    capturedGetTextFeatureScreenName = screenName
    return ""
  }

  static func reset() {
    stubbedDenseFeatures = nil
    capturedGetTextFeatureText = nil
    capturedGetTextFeatureScreenName = nil
  }
}

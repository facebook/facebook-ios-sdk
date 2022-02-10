/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import XCTest

@objcMembers
final class TestFeatureManager: NSObject, FeatureChecking, FeatureDisabling {

  var disabledFeatures = [SDKFeature]()
  var capturedFeatures = [SDKFeature]()
  var capturedCompletionBlocks: [SDKFeature: FBSDKFeatureManagerBlock] = [:]
  private var stubbedEnabledFeatures = [SDKFeature: Bool]()

  func check(_ feature: SDKFeature, completionBlock: @escaping FBSDKFeatureManagerBlock) {
    capturedFeatures.append(feature)
    capturedCompletionBlocks[feature] = completionBlock
  }

  func capturedFeaturesContains(_ feature: SDKFeature) -> Bool {
    capturedFeatures.contains(feature)
  }

  func disableFeature(_ feature: SDKFeature) {
    disabledFeatures.append(feature)
  }

  func disabledFeaturesContains(_ feature: SDKFeature) -> Bool {
    disabledFeatures.contains(feature)
  }

  /// Stub enabling features so that they pass the `isEnabled` check
  func enable(feature: SDKFeature) {
    stubbedEnabledFeatures[feature] = true
  }

  func isEnabled(_ feature: SDKFeature) -> Bool {
    stubbedEnabledFeatures[feature] ?? false
  }

  func completeCheck(
    forFeature feature: SDKFeature,
    with isEnabled: Bool
  ) {
    guard let completion = capturedCompletionBlocks[feature] else {
      return
    }
    completion(isEnabled)
  }
}

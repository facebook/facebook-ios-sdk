/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

// swiftformat:disable indent
@objcMembers
class TestOnDeviceMLModelManager: NSObject,
                                  EventProcessing, // swiftlint:disable:this indentation_width
                                  IntegrityParametersProcessorProvider,
                                  RulesFromKeyProvider {
  // swiftformat:enable indent

  var stubbedRules: [String: Any] = [:]
  var processSuggestedEventsCallCount = 0
  var stubbedProcessedEvents: String?
  var isEnabled = false
  var integrityParametersProcessor: AppEventsParameterProcessing?
  var rulesForKey: [String: Any] {
    get {
      stubbedRules
    }
    set {
      stubbedRules = newValue
    }
  }

  func processSuggestedEvents(
    _ textFeature: String,
    denseData: UnsafeMutablePointer<Float>?
  ) -> String {
    processSuggestedEventsCallCount += 1

    return stubbedProcessedEvents ?? ""
  }

  func enable() {
    isEnabled = true
  }

  func getRulesForKey(_ useCase: String) -> [String: Any]? {
    stubbedRules
  }
}

/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBAEMKit

@objcMembers
class TestInvocation: AEMInvocation {

  var attributionCallCount = 0
  var updateConversionCallCount = 0
  var isOptimizedEvent = false
  var shouldBoostPriority = false

  override func attributeEvent(
    _ event: String,
    currency: String?,
    value: NSNumber?,
    parameters: [String: Any]?,
    configs: [String: [AEMConfiguration]]?,
    shouldUpdateCache: Bool
  ) -> Bool {
    attributionCallCount += 1
    return true
  }

  override func updateConversionValue(
    withConfigs configs: [String: [AEMConfiguration]]?,
    event: String,
    shouldBoostPriority: Bool
  ) -> Bool {
    updateConversionCallCount += 1
    self.shouldBoostPriority = shouldBoostPriority
    return true
  }

  override func isOptimizedEvent(
    _ event: String,
    configs: [String: [AEMConfiguration]]?
  ) -> Bool {
    isOptimizedEvent
  }
}

/*
 * Copyright (c) Facebook, Inc. and its affiliates.
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

  override func attributeEvent(
    _ event: String,
    currency: String?,
    value: NSNumber?,
    parameters: [String: Any]?,
    configs: [String: [AEMConfiguration]]?
  ) -> Bool {
    attributionCallCount += 1
    return true
  }

  override func updateConversionValue(
    withConfigs configs: [String: [AEMConfiguration]]?
  ) -> Bool {
    updateConversionCallCount += 1
    return true
  }
}

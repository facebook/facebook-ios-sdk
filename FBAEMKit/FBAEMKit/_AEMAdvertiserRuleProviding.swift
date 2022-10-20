/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import Foundation

/**
 Describes anything that can provide instances of `AEMAdvertiserRuleMatching`
 */
@objc(FBAEMAdvertiserRuleProviding)
protocol _AEMAdvertiserRuleProviding {

  @objc(createRuleWithJson:)
  func createRule(json: String?) -> _AEMAdvertiserRuleMatching?

  @objc(createRuleWithDict:)
  func createRule(dictionary: [String: Any]) -> _AEMAdvertiserRuleMatching?
}

#endif

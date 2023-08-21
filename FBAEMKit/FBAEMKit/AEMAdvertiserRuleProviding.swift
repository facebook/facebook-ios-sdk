/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/**
 Describes anything that can provide instances of `AEMAdvertiserRuleMatching`
 */
protocol AEMAdvertiserRuleProviding {

  func createRule(json: String?) -> AEMAdvertiserRuleMatching?

  func createRule(dictionary: [String: Any]) -> AEMAdvertiserRuleMatching?
}

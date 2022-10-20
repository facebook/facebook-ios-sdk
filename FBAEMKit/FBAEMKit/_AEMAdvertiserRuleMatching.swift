/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import Foundation

@objc
protocol _AEMAdvertiserRuleMatching {
  func isMatchedEventParameters(_ eventParams: [String: Any]?) -> Bool
}

#endif

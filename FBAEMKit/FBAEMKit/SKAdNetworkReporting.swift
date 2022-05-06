/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import Foundation

@objc(FBSKAdNetworkReporting)
public protocol SKAdNetworkReporting {
  @objc
  func shouldCutoff() -> Bool

  @objc(isReportingEvent:)
  func isReportingEvent(_ event: String) -> Bool

  @objc
  func checkAndRevokeTimer()
}

#endif

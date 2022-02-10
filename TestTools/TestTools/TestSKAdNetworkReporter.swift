/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBAEMKit

public final class TestSKAdNetworkReporter: NSObject, SKAdNetworkReporting {

  public var cutOff = false
  public var reportingEvents: Set<String> = []

  public func shouldCutoff() -> Bool {
    cutOff
  }

  public func isReportingEvent(_ event: String) -> Bool {
    reportingEvents.contains(event)
  }

  public func checkAndRevokeTimer() {}
}

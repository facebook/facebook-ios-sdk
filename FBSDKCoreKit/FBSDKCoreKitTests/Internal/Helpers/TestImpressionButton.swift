/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import TestTools
import XCTest

import Foundation

final class TestImpressionButton: ImpressionLoggingButton, FBButtonImpressionLogging {
  var analyticsParameters: [AppEvents.ParameterName: Any]? = [.init("foo"): "bar"]
  var impressionTrackingEventName = AppEvents.Name("testImpressionTrackingEventName")
  var impressionTrackingIdentifier = "testImpressionTrackingIdentifier"
}

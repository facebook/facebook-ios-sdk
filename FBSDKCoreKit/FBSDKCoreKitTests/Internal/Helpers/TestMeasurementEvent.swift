/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

@objcMembers
final class TestMeasurementEvent: NSObject, AppLinkEventPosting {
  var capturedEventName: String?
  var capturedArgs = [String: String]()

  func postNotification(forEventName name: String, args: [String: Any]) {
    capturedEventName = name
    capturedArgs = args as? [String: String] ?? [:]
  }
}

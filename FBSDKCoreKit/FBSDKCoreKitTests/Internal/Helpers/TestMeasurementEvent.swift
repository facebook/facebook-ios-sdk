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
final class TestMeasurementEvent: NSObject, _AppLinkEventPosting {
  var capturedEventName: String?
  var capturedArgs = [String: String]()

  func postNotification(eventName name: String, arguments args: [String: Any]) {
    capturedEventName = name
    capturedArgs = args as? [String: String] ?? [:]
  }
}

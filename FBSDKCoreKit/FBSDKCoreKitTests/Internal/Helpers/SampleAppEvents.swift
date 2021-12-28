/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objcMembers
class SampleAppEvents: NSObject {

  static var validEvent: [String: String] {
    ["_eventName": "event1"]
  }

  static func validEvent(withName name: String) -> [String: String] {
    ["_eventName": name]
  }
}

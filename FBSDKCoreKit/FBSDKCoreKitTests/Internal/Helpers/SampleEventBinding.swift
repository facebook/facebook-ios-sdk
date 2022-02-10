/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objcMembers
final class SampleEventBinding: NSObject {

  static func createValid(withName name: String) -> EventBinding {
    let logger = TestEventLogger()
    return EventBinding(
      json: SampleRawRemoteEventBindings.rawBinding(name: name),
      eventLogger: logger
    )
  }

  static func createEventLogger() -> TestEventLogger {
    TestEventLogger()
  }

  static var validEventBindings: [EventBinding] {
    SampleRawRemoteEventBindings.bindings.compactMap {
      EventBinding(json: $0, eventLogger: createEventLogger())
    }
  }
}

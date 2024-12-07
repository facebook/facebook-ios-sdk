/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objcMembers
final class TestAppEventsState: _AppEventsState {
  var capturedEventDictionary: [String: Any]?
  var capturedIsImplicit = false
  var isAddEventCalled = false

  override init(token: String?, appID: String?) {
    super.init(token: token, appID: appID)
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func addEvent(
    _ eventDictionary: [String: Any],
    isImplicit: Bool,
    withOperationalParameters: [AppOperationalDataType: [String: Any]]?
  ) {
    capturedEventDictionary = eventDictionary
    capturedIsImplicit = isImplicit
    isAddEventCalled = true

    super.addEvent(
      eventDictionary,
      isImplicit: isImplicit,
      withOperationalParameters: withOperationalParameters
    )
  }
}

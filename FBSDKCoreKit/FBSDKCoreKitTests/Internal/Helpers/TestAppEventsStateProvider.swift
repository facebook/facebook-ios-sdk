/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objcMembers
final class TestAppEventsStateProvider: NSObject, AppEventsStateProviding {
  var state: TestAppEventsState?
  var capturedTokenString: String?
  var capturedAppID: String?
  var isCreateStateCalled = false

  func createState(tokenString: String, appID: String) -> AppEventsState {
    isCreateStateCalled = true
    capturedTokenString = tokenString
    capturedAppID = appID
    state = TestAppEventsState(token: tokenString, appID: appID)
    return state! // swiftlint:disable:this force_unwrapping
  }
}

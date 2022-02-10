/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objcMembers
final class TestAppEventsStateStore: NSObject, AppEventsStatePersisting {
  var capturedPersistedState: [Any] = []
  var retrievePersistedAppEventStatesWasCalled = false
  var clearPersistedAppEventsWasCalled = false
  var persistedStatesToBeRetrieved: [Any] = []

  func clearPersistedAppEventsStates() {
    clearPersistedAppEventsWasCalled = true
    capturedPersistedState = []
  }

  func persistAppEventsData(_ appEventsState: AppEventsState) {
    capturedPersistedState.append(appEventsState)
  }

  func retrievePersistedAppEventsStates() -> [Any] {
    retrievePersistedAppEventStatesWasCalled = true
    return Array(persistedStatesToBeRetrieved)
  }
}

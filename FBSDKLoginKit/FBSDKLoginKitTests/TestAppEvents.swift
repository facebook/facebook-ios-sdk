/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@objcMembers
class TestAppEvents: AppEvents {
  var capturedParameters: [String: Any]?

  override func logInternalEvent(
    _ eventName: AppEvents.Name,
    parameters: [String: Any]?,
    isImplicitlyLogged: Bool
  ) {
    capturedParameters = parameters
  }
}

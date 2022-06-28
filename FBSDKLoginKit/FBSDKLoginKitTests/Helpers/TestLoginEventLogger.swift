/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit

final class TestLoginEventLogger: LoginEventLogging {
  var capturedParameters: [AppEvents.ParameterName: Any]?
  var capturedEventName: AppEvents.Name?
  var flushBehavior = AppEvents.FlushBehavior.auto

  func logInternalEvent(
    _ eventName: AppEvents.Name,
    parameters: [AppEvents.ParameterName: Any]?,
    isImplicitlyLogged: Bool
  ) {
    capturedEventName = eventName
    capturedParameters = parameters
  }

  func flush() {}
}

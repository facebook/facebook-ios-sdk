/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKShareKit

import FBSDKCoreKit

final class TestShareEventLogger: ShareEventLogging {
  var logInternalEventName: AppEvents.Name?
  var logInternalEventParameters: [AppEvents.ParameterName: Any]?
  var logInternalEventIsImplicitlyLogged: Bool? // swiftlint:disable:this discouraged_optional_boolean
  var logInternalEventAccessToken: AccessToken?

  func logInternalEvent(
    _ eventName: AppEvents.Name,
    parameters: [AppEvents.ParameterName: Any]?,
    isImplicitlyLogged: Bool,
    accessToken: AccessToken?
  ) {
    logInternalEventName = eventName
    logInternalEventParameters = parameters
    logInternalEventIsImplicitlyLogged = isImplicitlyLogged
    logInternalEventAccessToken = accessToken
  }
}

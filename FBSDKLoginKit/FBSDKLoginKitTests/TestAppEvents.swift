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
final class TestAppEvents: AppEvents {
  var capturedParameters: [AppEvents.ParameterName: Any]?

  override func logInternalEvent(
    _ eventName: AppEvents.Name,
    parameters: [AppEvents.ParameterName: Any]?,
    isImplicitlyLogged: Bool
  ) {
    capturedParameters = parameters
  }
}

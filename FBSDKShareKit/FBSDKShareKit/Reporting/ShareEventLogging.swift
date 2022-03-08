/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

protocol ShareEventLogging {
  func logInternalEvent(
    _ eventName: AppEvents.Name,
    parameters: [AppEvents.ParameterName: Any]?,
    isImplicitlyLogged: Bool,
    accessToken: AccessToken?
  )
}

extension AppEvents: ShareEventLogging {}

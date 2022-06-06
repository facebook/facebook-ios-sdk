/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

#if !os(tvOS)

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.
 - Warning INTERNAL:  DO NOT USE
 */
@objcMembers
@objc(FBSDKLoginCompleterFactory)
public final class _LoginCompleterFactory: NSObject, LoginCompleterFactoryProtocol {

  public func createLoginCompleter(
    urlParameters parameters: [String: Any],
    appID: String
  ) -> _LoginCompleting {
    _LoginURLCompleter(urlParameters: parameters, appID: appID)
  }
}

#endif

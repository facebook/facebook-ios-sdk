/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import AuthenticationServices

public struct SampleError: Error {
  public static let WebAuthSessionCancelledError = ASWebAuthenticationSessionError(.canceledLogin, userInfo: [:])

  public init() {}
}

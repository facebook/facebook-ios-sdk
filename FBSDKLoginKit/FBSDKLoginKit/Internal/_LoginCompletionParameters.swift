/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import FBSDKCoreKit
import Foundation

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.
 - Warning INTERNAL:  DO NOT USE

 Structured interface for accessing the parameters used to complete a log in request.
 If `authenticationTokenString` is non-`nil`, the authentication succeeded. If `error` is
 non-`nil` the request failed. If both are `nil`, the request was cancelled.
 */
@objcMembers
@objc(FBSDKLoginCompletionParameters)
public final class _LoginCompletionParameters: NSObject {
  public var authenticationToken: AuthenticationToken?
  public var profile: Profile?
  public var accessTokenString: String?
  public var nonceString: String?
  public var authenticationTokenString: String?
  public var code: String?
  public var permissions: Set<FBPermission>?
  public var declinedPermissions: Set<FBPermission>?
  public var expiredPermissions: Set<FBPermission>?
  public var appID: String?
  public var userID: String?
  public var error: Error?
  public var expirationDate: Date?
  public var dataAccessExpirationDate: Date?
  public var challenge: String?
  public var graphDomain: String?
}

#endif

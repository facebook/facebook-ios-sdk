/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

/// A configuration to use for modifying the behavior of a login attempt.
@objcMembers
@objc(FBSDKLoginConfiguration)
public final class LoginConfiguration: NSObject {

  /// The nonce that the configuration was created with.
  /// A unique nonce will be used if none is provided to the initializer.
  public let nonce: String

  /// The tracking  preference. Defaults to `.enabled`.
  public let tracking: LoginTracking

  /// The requested permissions for the login attempt. Defaults to an empty set.
  public let requestedPermissions: Set<FBPermission>

  /// The Messenger Page Id associated with this login request.
  public let messengerPageId: String?

  /// The auth type associated with this login request.
  public let authType: LoginAuthType?

  /// The code verifier used in the PKCE process.
  /// If not provided, a code verifier will be randomly generated.
  public let codeVerifier: CodeVerifier

  /**
   Attempts to initialize a new configuration with the expected parameters.

   @param permissions the requested permissions for a login attempt. Permissions must be an array of strings that do not contain whitespace.
   @param tracking the tracking preference to use for a login attempt.
   @param nonce an optional nonce to use for the login attempt. A valid nonce must be a non-empty string without whitespace.
   Creation of the configuration will fail if the nonce is invalid.
   @param messengerPageId the associated page id  to use for a login attempt.
   */
  @objc(initWithPermissions:tracking:nonce:messengerPageId:)
  public convenience init?(
    permissions: [String],
    tracking: LoginTracking,
    nonce: String,
    messengerPageId: String?
  ) {
    self.init(
      permissions: permissions,
      tracking: tracking,
      nonce: nonce,
      messengerPageId: messengerPageId,
      authType: .rerequest
    )
  }

  /**
   Attempts to initialize a new configuration with the expected parameters.

   @param permissions the requested permissions for a login attempt. Permissions must be an array of strings that do not contain whitespace.
   @param tracking the tracking preference to use for a login attempt.
   @param nonce an optional nonce to use for the login attempt. A valid nonce must be a non-empty string without whitespace.
   Creation of the configuration will fail if the nonce is invalid.
   @param messengerPageId the associated page id  to use for a login attempt.
   @param authType auth_type param to use for login.
   */
  @objc(initWithPermissions:tracking:nonce:messengerPageId:authType:)
  public convenience init?(
    permissions: [String],
    tracking: LoginTracking,
    nonce: String,
    messengerPageId: String?,
    authType: LoginAuthType?
  ) {
    self.init(
      permissions: permissions,
      tracking: tracking,
      nonce: nonce,
      messengerPageId: messengerPageId,
      authType: authType,
      codeVerifier: CodeVerifier()
    )
  }

  /**
   Attempts to initialize a new configuration with the expected parameters.

   @param permissions the requested permissions for a login attempt. Permissions must be an array of strings that do not contain whitespace.
   @param tracking the tracking preference to use for a login attempt.
   @param nonce an optional nonce to use for the login attempt. A valid nonce must be a non-empty string without whitespace.
   Creation of the configuration will fail if the nonce is invalid.
   */
  @objc(initWithPermissions:tracking:nonce:)
  public convenience init?(
    permissions: [String],
    tracking: LoginTracking,
    nonce: String
  ) {
    self.init(
      permissions: permissions,
      tracking: tracking,
      nonce: nonce,
      messengerPageId: nil
    )
  }

  /**
   Attempts to initialize a new configuration with the expected parameters.

   @param permissions the requested permissions for the login attempt. Permissions must be an array of strings that do not contain whitespace.
   @param tracking the tracking preference to use for a login attempt.
   @param messengerPageId the associated page id  to use for a login attempt.
   */
  @objc(initWithPermissions:tracking:messengerPageId:)
  public convenience init?(
    permissions: [String],
    tracking: LoginTracking,
    messengerPageId: String?
  ) {
    self.init(
      permissions: permissions,
      tracking: tracking,
      nonce: UUID().uuidString,
      messengerPageId: messengerPageId
    )
  }

  /**
   Attempts to initialize a new configuration with the expected parameters.

   @param permissions the requested permissions for the login attempt. Permissions must be an array of strings that do not contain whitespace.
   @param tracking the tracking preference to use for a login attempt.
   @param messengerPageId the associated page id  to use for a login attempt.
   @param authType auth_type param to use for login.
   */
  @objc(initWithPermissions:tracking:messengerPageId:authType:)
  public convenience init?(
    permissions: [String],
    tracking: LoginTracking,
    messengerPageId: String?,
    authType: LoginAuthType?
  ) {
    self.init(
      permissions: permissions,
      tracking: tracking,
      nonce: UUID().uuidString,
      messengerPageId: messengerPageId,
      authType: authType
    )
  }

  /**
   Attempts to initialize a new configuration with the expected parameters.

   @param permissions the requested permissions for a login attempt. Permissions must be an array of strings that do not contain whitespace.
   @param tracking the tracking preference to use for a login attempt.
   @param nonce an optional nonce to use for the login attempt. A valid nonce must be a non-empty string without whitespace.
   Creation of the configuration will fail if the nonce is invalid.
   @param messengerPageId the associated page id  to use for a login attempt.
   @param authType auth_type param to use for login.
   @param codeVerifier The code verifier used in the PKCE process.
   */
  @objc(initWithPermissions:tracking:nonce:messengerPageId:authType:codeVerifier:)
  public init?(
    permissions: [String],
    tracking: LoginTracking,
    nonce: String,
    messengerPageId: String?,
    authType: LoginAuthType?,
    codeVerifier: CodeVerifier
  ) {

    guard NonceValidator.isValid(nonce: nonce) else {
      let message = "Invalid nonce:\(nonce) provided to login configuration. Returning nil"
      Logger.singleShotLogEntry(.developerErrors, logEntry: message)
      return nil
    }

    guard
      let permissions = FBPermission.permissions(fromRawPermissions: Set(permissions))
    else {
      let message = "Invalid combination of permissions provided to login configuration."
      Logger.singleShotLogEntry(.developerErrors, logEntry: message)
      return nil
    }

    if let authType = authType,
       ![.rerequest, .reauthorize].contains(authType) {
      let message = "Invalid auth_type provided to login configuration."
      Logger.singleShotLogEntry(.developerErrors, logEntry: message)
      return nil
    }

    requestedPermissions = permissions
    self.tracking = tracking
    self.nonce = nonce
    self.messengerPageId = messengerPageId
    self.authType = authType
    self.codeVerifier = codeVerifier
    super.init()
  }

  /**
   Attempts to initialize a new configuration with the expected parameters.

   @param permissions the requested permissions for the login attempt. Permissions must be an array of strings that do not contain whitespace.
   @param tracking the tracking preference to use for a login attempt.
   */
  @objc(initWithPermissions:tracking:)
  public convenience init?(
    permissions: [String],
    tracking: LoginTracking
  ) {
    self.init(
      permissions: permissions,
      tracking: tracking,
      nonce: UUID().uuidString
    )
  }

  /**
   Attempts to initialize a new configuration with the expected parameters.

   @param tracking the login tracking preference to use for a login attempt.
   */
  @objc(initWithTracking:)
  public convenience init?(tracking: LoginTracking) {
    self.init(
      permissions: [],
      tracking: tracking
    )
  }

  /**
   Given a string, return the corresponding FBSDKLoginAuthType. Returns nil if the string cannot be mapped to a valid auth type

   @param rawValue the raw auth type.
   */
  @available(*, deprecated, message: "This method is deprecated and will be removed in the next major release.")
  @objc(authTypeForString:)
  public static func authType(for rawValue: String) -> LoginAuthType? {
    let map = [
      "rerequest": LoginAuthType.rerequest,
      "reauthorize": LoginAuthType.reauthorize,
    ]

    return map[rawValue]
  }

  /**
   Attempts to allocate and initialize a new configuration with the expected parameters.

   - parameter permissions: The requested permissions for the login attempt.
   Defaults to an empty `Permission` array.
   - parameter tracking: The tracking preference to use for a login attempt. Defaults to `.enabled`
   - parameter nonce: An optional nonce to use for the login attempt.
    A valid nonce must be an alphanumeric string without whitespace.
    Creation of the configuration will fail if the nonce is invalid. Defaults to a `UUID` string.
   - parameter messengerPageId: An optional page id to use for a login attempt. Defaults to `nil`
   - parameter authType: An optional auth type to use for a login attempt. Defaults to `.rerequest`
   - parameter codeVerifier: An optional codeVerifier used for the PKCE process.
   If not provided, this will be randomly generated.
   */
  public convenience init?(
    permissions: Set<Permission> = [],
    tracking: LoginTracking = .enabled,
    nonce: String = UUID().uuidString,
    messengerPageId: String? = nil,
    authType: LoginAuthType? = .rerequest,
    codeVerifier: CodeVerifier = CodeVerifier()
  ) {
    self.init(
      permissions: permissions.map { $0.name },
      tracking: tracking,
      nonce: nonce,
      messengerPageId: messengerPageId,
      authType: authType,
      codeVerifier: codeVerifier
    )
  }
}

#endif

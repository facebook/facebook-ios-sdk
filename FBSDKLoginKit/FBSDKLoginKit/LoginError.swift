/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/// Custom error type for login errors in the login error domain
public struct LoginError: CustomNSError, Hashable {

  let _nsError: NSError? // swiftlint:disable:this identifier_name

  public let errorCode: Int

  public let errorUserInfo: [String: Any]

  public init(_nsError nsError: NSError) {
    _nsError = nsError
    errorCode = nsError.code
    errorUserInfo = nsError.userInfo
  }

  public init(_ code: Code, userInfo: [String: Any] = [:]) {
    _nsError = nil
    errorCode = code.rawValue
    errorUserInfo = userInfo
  }

  public static var errorDomain: String { LoginErrorDomain }

  public typealias Code = LoginErrorCode

  /// Reserved
  public static var reserved: Code { .reserved }

  /// The error code for unknown errors
  public static var unknown: Code { .unknown }

  /// The user's password has changed and must log in again
  public static var passwordChanged: Code { .passwordChanged }

  /// The user must log in to their account on www.facebook.com to restore access
  public static var userCheckpointed: Code { .userCheckpointed }

  /// Indicates a failure to request new permissions because the user has changed
  public static var userMismatch: Code { .userMismatch }

  /// The user must confirm their account with Facebook before logging in
  public static var unconfirmedUser: Code { .unconfirmedUser }

  /// The Accounts framework failed without returning an error, indicating the app's slider in the
  /// iOS Facebook Settings (device Settings -> Facebook -> App Name) has been disabled.
  public static var systemAccountAppDisabled: Code { .systemAccountAppDisabled }

  /// An error occurred related to Facebook system Account store
  public static var systemAccountUnavailable: Code { .systemAccountUnavailable }

  /// The login response was missing a valid challenge string
  public static var badChallengeString: Code { .badChallengeString }

  /// The ID token returned in login response was invalid
  public static var invalidIDToken: Code { .invalidIDToken }

  /// A current access token was required and not provided
  public static var missingAccessToken: Code { .missingAccessToken }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    if let leftError = lhs._nsError,
       let rightError = rhs._nsError {
      return leftError === rightError
    } else {
      return lhs.errorCode == rhs.errorCode
    }
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(errorCode)
  }
}

/// Custom error codes for login errors in the login error domain
@objc(FBSDKLoginError) public enum LoginErrorCode: Int, @unchecked Sendable, Equatable {

  public typealias _ErrorType = LoginError

  /// Reserved
  case reserved = 300

  /// The error code for unknown errors
  case unknown

  /// The user's password has changed and must log in again
  case passwordChanged

  /// The user must log in to their account on www.facebook.com to restore access
  case userCheckpointed

  /// Indicates a failure to request new permissions because the user has changed
  case userMismatch

  /// The user must confirm their account with Facebook before logging in
  case unconfirmedUser

  /// The Accounts framework failed without returning an error, indicating the app's slider in the
  /// iOS Facebook Settings (device Settings -> Facebook -> App Name) has been disabled.
  case systemAccountAppDisabled

  /// An error occurred related to Facebook system Account store
  case systemAccountUnavailable

  /// The login response was missing a valid challenge string
  case badChallengeString

  /// The ID token returned in login response was invalid
  case invalidIDToken

  /// A current access token was required and not provided
  case missingAccessToken
}

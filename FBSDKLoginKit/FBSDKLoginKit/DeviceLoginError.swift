/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/// Custom error type for device login errors in the login error domain
public struct DeviceLoginError: CustomNSError, Hashable {

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

  public typealias Code = DeviceLoginErrorCode

  /// Your device is polling too frequently.
  public static var excessivePolling: Code { .excessivePolling }

  /// User has declined to authorize your application.
  public static var authorizationDeclined: Code { .authorizationDeclined }

  /// User has not yet authorized your application. Continue polling.
  public static var authorizationPending: Code { .authorizationPending }

  /// The code you entered has expired.
  public static var codeExpired: Code { .codeExpired }

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

/// Custom error codes for device login errors in the login error domain
@objc(FBSDKDeviceLoginError) public enum DeviceLoginErrorCode: Int, @unchecked Sendable, Equatable {

  public typealias _ErrorType = DeviceLoginError

  /// Your device is polling too frequently.
  case excessivePolling = 1349172

  /// User has declined to authorize your application.
  case authorizationDeclined = 1349173

  /// User has not yet authorized your application. Continue polling.
  case authorizationPending = 1349174

  /// The code you entered has expired.
  case codeExpired = 1349152
}

/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objc(FBSDKErrorFactory)
public final class _ErrorFactory: NSObject, ErrorCreating {

  private enum Keys {
    static let errorDomain = "com.facebook.sdk.core"
    static let message = "com.facebook.sdk:FBSDKErrorDeveloperMessageKey"
    static let argumentName = "com.facebook.sdk:FBSDKErrorArgumentNameKey"
    static let argumentValue = "com.facebook.sdk:FBSDKErrorArgumentValueKey"
  }

  // MARK: - General Errors

  @objc(errorWithCode:userInfo:message:underlyingError:)
  public func error(
    code: Int,
    userInfo: [String: Any]? = nil,
    message: String?,
    underlyingError: Error?
  ) -> Error {
    error(
      domain: Keys.errorDomain,
      code: code,
      userInfo: userInfo,
      message: message,
      underlyingError: underlyingError
    )
  }

  @objc(errorWithDomain:code:userInfo:message:underlyingError:)
  public func error(
    domain: String,
    code: Int,
    userInfo: [String: Any]? = nil,
    message: String?,
    underlyingError: Error?
  ) -> Error {

    var fullUserInfo = userInfo ?? [:]
    if let message = message {
      fullUserInfo[Keys.message] = message
    }

    if let underlyingError = underlyingError {
      fullUserInfo[NSUnderlyingErrorKey] = underlyingError
    }

    reportError(code: code, domain: domain, message: message)
    return NSError(domain: domain, code: code, userInfo: fullUserInfo)
  }

  // MARK: - Invalid Argument Errors

  @objc(invalidArgumentErrorWithName:value:message:underlyingError:)
  public func invalidArgumentError(
    name: String,
    value: Any?,
    message: String?,
    underlyingError: Error?
  ) -> Error {
    invalidArgumentError(
      domain: Keys.errorDomain,
      name: name,
      value: value,
      message: message,
      underlyingError: underlyingError
    )
  }

  @objc(invalidArgumentErrorWithDomain:name:value:message:underlyingError:)
  public func invalidArgumentError(
    domain: String,
    name: String,
    value: Any?,
    message: String?,
    underlyingError: Error?
  ) -> Error {
    let message = message ?? "Invalid value for \(name): \(String(describing: value))"
    var userInfo = [String: Any]()
    userInfo[Keys.argumentName] = name

    if let value = value {
      userInfo[Keys.argumentValue] = value
    }

    return error(
      domain: domain,
      code: CoreError.errorInvalidArgument.rawValue,
      userInfo: userInfo,
      message: message,
      underlyingError: underlyingError
    )
  }

  // MARK: - Required Argument Errors

  @objc(requiredArgumentErrorWithName:message:underlyingError:)
  public func requiredArgumentError(name: String, message: String?, underlyingError: Error?) -> Error {
    requiredArgumentError(domain: Keys.errorDomain, name: name, message: message, underlyingError: underlyingError)
  }

  @objc(requiredArgumentErrorWithDomain:name:message:underlyingError:)
  public func requiredArgumentError(
    domain: String,
    name: String,
    message: String?,
    underlyingError: Error?
  ) -> Error {
    let message = message ?? "Value for \(name) is required."
    return invalidArgumentError(
      domain: domain,
      name: name,
      value: nil,
      message: message,
      underlyingError: underlyingError
    )
  }

  @objc(unknownErrorWithMessage:userInfo:)
  public func unknownError(message: String?, userInfo: [String: Any]? = nil) -> Error {
    error(code: CoreError.errorUnknown.rawValue, userInfo: userInfo, message: message, underlyingError: nil)
  }

  // MARK: - Reporting

  func reportError(code: Int, domain: String, message: String?) {
    guard
      let reporter = try? Self.getDependencies().reporter
    else {
      return
    }
    reporter.saveError(code, errorDomain: domain, message: message)
  }
}

// MARK: - Dependencies

extension _ErrorFactory: DependentAsType {
  struct TypeDependencies {
    var reporter: ErrorReporting
  }

  static var configuredDependencies: TypeDependencies?

  static var defaultDependencies: TypeDependencies? = TypeDependencies(reporter: ErrorReporter.shared)
}

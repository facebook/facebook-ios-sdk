/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@objcMembers
public final class TestErrorFactory: NSObject, ErrorCreating {
  public func error(
    code: Int,
    userInfo: [String: Any]? = nil,
    message: String?,
    underlyingError: Error?
  ) -> Error {
    TestSDKError(
      type: .general,
      code: code,
      userInfo: userInfo,
      message: message,
      underlyingError: underlyingError
    )
  }

  public func error(
    domain: String,
    code: Int,
    userInfo: [String: Any]? = nil,
    message: String?,
    underlyingError: Error?
  ) -> Error {
    TestSDKError(
      type: .general,
      domain: domain,
      code: code,
      userInfo: userInfo,
      message: message,
      underlyingError: underlyingError
    )
  }

  public func invalidArgumentError(
    name: String,
    value: Any?,
    message: String?,
    underlyingError: Error?
  ) -> Error {
    TestSDKError(
      type: .invalidArgument,
      name: name,
      value: value,
      message: message,
      underlyingError: underlyingError
    )
  }

  public func invalidArgumentError(
    domain: String,
    name: String,
    value: Any?,
    message: String?,
    underlyingError: Error?
  ) -> Error {
    TestSDKError(
      type: .invalidArgument,
      domain: domain,
      name: name,
      value: value,
      message: message,
      underlyingError: underlyingError
    )
  }

  public func requiredArgumentError(
    name: String,
    message: String?,
    underlyingError: Error?
  ) -> Error {
    TestSDKError(
      type: .requiredArgument,
      name: name,
      message: message,
      underlyingError: underlyingError
    )
  }

  public func requiredArgumentError(
    domain: String,
    name: String,
    message: String?,
    underlyingError: Error?
  ) -> Error {
    TestSDKError(
      type: .requiredArgument,
      domain: domain,
      name: name,
      message: message,
      underlyingError: underlyingError
    )
  }

  public func unknownError(message: String?, userInfo: [String: Any]? = nil) -> Error {
    TestSDKError(type: .unknown, userInfo: userInfo, message: message)
  }
}

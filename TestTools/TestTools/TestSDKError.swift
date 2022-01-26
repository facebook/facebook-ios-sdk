/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objc public enum TestSDKErrorType: Int {
  case general
  case invalidArgument
  case requiredArgument
  case unknown
}

@objcMembers
public final class TestSDKError: NSError {
  public let type: TestSDKErrorType
  public let name: String?
  public let value: Any?
  public let message: String?
  public let underlyingError: Error?

  public static let testErrorDomain = "TestSDKError"
  public static let testErrorCode = 141414

  public init(
    type: TestSDKErrorType,
    domain: String = TestSDKError.testErrorDomain,
    code: Int = TestSDKError.testErrorCode,
    userInfo: [String: Any]? = nil,
    name: String? = nil,
    value: Any? = nil,
    message: String? = nil,
    underlyingError: Error? = nil
  ) {
    self.type = type
    self.name = name
    self.value = value
    self.message = message
    self.underlyingError = underlyingError
    super.init(domain: domain, code: code, userInfo: userInfo)
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func copy(with zone: NSZone? = nil) -> Any {
    self
  }
}

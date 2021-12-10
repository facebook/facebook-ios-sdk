/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@objcMembers
class TestSDKError: NSError {
  @objc enum ErrorType: Int {
    case general
    case invalidArgument
    case requiredArgument
    case unknown
  }

  let type: ErrorType
  let name: String?
  let value: Any?
  let message: String?
  let underlyingError: Error?

  static let testErrorDomain = "TestSDKError"
  static let testErrorCode = 141414

  init(
    type: ErrorType,
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
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func copy(with zone: NSZone? = nil) -> Any {
    self
  }
}

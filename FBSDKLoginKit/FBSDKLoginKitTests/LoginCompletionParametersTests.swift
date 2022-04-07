/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit

import XCTest

final class LoginCompletionParametersTests: XCTestCase {

  func testCreationWithError() throws {
    let error = NSError(domain: "com.facebook.sdk.login", code: 301)
    let parameters = LoginCompletionParameters(error: error)
    let parameterError = try XCTUnwrap(parameters.error)

    XCTAssertEqual(parameterError as NSError, error, .createWithError)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let createWithError = "creates completion parameters with an error"
}

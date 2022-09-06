/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import MetaLogin

import AuthenticationServices
import XCTest

// swiftlint:disable:next type_name
final class DefaultASWebAuthenticationSessionFactoryTests: XCTestCase {
  func testMakingSession() {
    let session = DefaultASWebAuthenticationSessionFactory()
      .makeSession(
        url: .sample,
        callbackURLScheme: .sampleScheme
      ) { _, _ in }

    XCTAssertEqual(
      String(describing: type(of: session)),
      "ASWebAuthenticationSession",
      .standardSession
    )
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let standardSession = "A default web authentication session factory produces a standard session"
}

// MARK: - Test Values

fileprivate extension URL {
  static let sample = URL(string: "https://facebook.com/auth")!
}

fileprivate extension String {
  static let sampleScheme = "auth"
}

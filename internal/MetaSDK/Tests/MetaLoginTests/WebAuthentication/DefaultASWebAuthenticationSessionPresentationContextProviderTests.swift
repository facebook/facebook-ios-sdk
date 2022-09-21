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
final class DefaultASWebAuthenticationSessionPresentationContextProviderTests: XCTestCase {

  // swiftlint:disable:next implicitly_unwrapped_optional
  var provider: DefaultASWebAuthenticationSessionPresentationContextProvider!

  override func setUp() {
    super.setUp()
    provider = DefaultASWebAuthenticationSessionPresentationContextProvider()
  }

  override func tearDown() {
    provider = nil
    super.tearDown()
  }

  func testProvidesDefaultPresentationAnchor() {
    let anchorCreated = expectation(description: "Anchor provided")
    var potentialAnchor: ASPresentationAnchor!
    DispatchQueue.global(qos: .userInitiated).async { [self] in
      potentialAnchor = provider.presentationAnchor(for: TestASWebAuthenticationSession())
      anchorCreated.fulfill()
    }

    waitForExpectations(timeout: 2)
    let anchor: ASPresentationAnchor = potentialAnchor

    XCTAssertEqual(
      String(describing: type(of: anchor)),
      "UIWindow",
      .providesPresentationAnchor
    )
  }
}

// swiftformat:disable extensionaccesscontrol

// MARK: - Assumptions

fileprivate extension String {
  static let providesPresentationAnchor = """
    A default presentation context provider provides a default presentation anchor
    """
}

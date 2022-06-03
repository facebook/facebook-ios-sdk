/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit

import TestTools
import XCTest

final class LoginCompleterFactoryTests: XCTestCase {

  func testCreatingCompleterWithDependencies() {
    let completer = _LoginCompleterFactory().createLoginCompleter(
      urlParameters: [:],
      appID: name
    )
    XCTAssertTrue(
      completer is _LoginURLCompleter,
      "Should create the expected concrete type of login completer"
    )
  }
}

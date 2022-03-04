/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import XCTest

final class URLSchemeTests: XCTestCase {
  func testSchemeRawValues() {
    XCTAssertEqual(URLScheme.facebookAPI.rawValue, "fbapi")
    XCTAssertEqual(URLScheme.messengerApp.rawValue, "fb-messenger-share-api")
    XCTAssertEqual(URLScheme.https.rawValue, "https")
    XCTAssertEqual(URLScheme.http.rawValue, "http")
    XCTAssertEqual(URLScheme.web.rawValue, "web")
  }
}

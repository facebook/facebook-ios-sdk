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
    XCTAssertEqual(URLSchemeEnum.facebookAPI.rawValue, "fbapi")
    XCTAssertEqual(URLSchemeEnum.messengerApp.rawValue, "fb-messenger-share-api")
    XCTAssertEqual(URLSchemeEnum.https.rawValue, "https")
    XCTAssertEqual(URLSchemeEnum.http.rawValue, "http")
    XCTAssertEqual(URLSchemeEnum.web.rawValue, "web")
  }
}

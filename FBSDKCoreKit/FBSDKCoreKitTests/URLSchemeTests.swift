/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

final class URLSchemeTests: XCTestCase {
  func testSchemeRawValues() {
    XCTAssertEqual(URLScheme.facebookApp.rawValue, "fbauth2")
    XCTAssertEqual(URLScheme.facebookAPI.rawValue, "fbapi")
    XCTAssertEqual(URLScheme.messengerApp.rawValue, "fb-messenger-share-api")
    XCTAssertEqual(URLScheme.masqueradePlayer.rawValue, "msqrdplayer")
    XCTAssertEqual(URLScheme.https.rawValue, "https")
    XCTAssertEqual(URLScheme.http.rawValue, "http")
    XCTAssertEqual(URLScheme.web.rawValue, "web")
  }
}

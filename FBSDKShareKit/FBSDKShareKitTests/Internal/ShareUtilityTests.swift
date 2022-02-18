/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKShareKit

import XCTest

final class ShareUtilityTests: XCTestCase {
  func testShareLinkContentValidationWithNilValues() throws {
    let content = ShareLinkContent()
    XCTAssertNotNil(content.shareUUID)
    XCTAssertNoThrow(try content.validate(options: []))
  }

  func testShareLinkContentValidationWithValidValues() throws {
    let content = ShareLinkContent()
    content.contentURL = ShareModelTestUtility.contentURL
    content.peopleIDs = []
    content.placeID = ShareModelTestUtility.placeID
    content.ref = ShareModelTestUtility.ref
    XCTAssertNotNil(content.shareUUID)
    XCTAssertNoThrow(try content.validate(options: []))
  }

  func testShareLinkContentParameters() {
    let content = ShareLinkContent()
    content.contentURL = ShareModelTestUtility.contentURL
    XCTAssertNotNil(content.shareUUID)
    let parameters = _ShareUtility.bridgeParameters(for: content, options: [], shouldFailOnDataError: true)
    XCTAssertEqual(
      content.contentURL,
      parameters["messenger_link"] as? URL,
      "Incorrect messenger_link param."
    )
  }
}

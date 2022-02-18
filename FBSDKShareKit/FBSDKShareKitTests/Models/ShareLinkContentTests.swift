/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKShareKit

import FBSDKCoreKit
import XCTest

final class ShareLinkContentTests: XCTestCase {

  func testProperties() {
    let content = ShareModelTestUtility.linkContent
    XCTAssertEqual(content.contentURL, ShareModelTestUtility.contentURL)
    XCTAssertEqual(content.hashtag, ShareModelTestUtility.hashtag)
    XCTAssertEqual(content.peopleIDs, ShareModelTestUtility.peopleIDs)
    XCTAssertEqual(content.placeID, ShareModelTestUtility.placeID)
    XCTAssertEqual(content.ref, ShareModelTestUtility.ref)
    XCTAssertEqual(content.quote, ShareModelTestUtility.quote)
  }

  func testValidationWithValidContent() {
    XCTAssertNoThrow(
      try _ShareUtility.validateShareContent(ShareModelTestUtility.linkContent)
    )
  }
}

/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

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

  func testCoding() throws {
    let content = ShareModelTestUtility.linkContent
    let data = NSKeyedArchiver.archivedData(withRootObject: content)
    let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
    unarchiver.requiresSecureCoding = true
    let unarchivedObject = try XCTUnwrap(
      unarchiver.decodeObject(of: ShareLinkContent.self, forKey: NSKeyedArchiveRootObjectKey)
    )

    XCTAssertEqual(unarchivedObject.contentURL, content.contentURL)
    XCTAssertEqual(unarchivedObject.hashtag, content.hashtag)
    XCTAssertEqual(unarchivedObject.peopleIDs, content.peopleIDs)
    XCTAssertEqual(unarchivedObject.placeID, content.placeID)
    XCTAssertEqual(unarchivedObject.ref, content.ref)
    XCTAssertEqual(unarchivedObject.pageID, content.pageID)
    XCTAssertEqual(unarchivedObject.shareUUID, content.shareUUID)
    XCTAssertEqual(unarchivedObject.quote, content.quote)
  }

  func testValidationWithValidContent() {
    XCTAssertNoThrow(
      try _ShareUtility.validateShare(
        ShareModelTestUtility.linkContent,
        bridgeOptions: []
      )
    )
  }
}

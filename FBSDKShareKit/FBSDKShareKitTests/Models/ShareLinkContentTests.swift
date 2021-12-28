/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import XCTest

class ShareLinkContentTests: XCTestCase {

  func testProperties() {
    let content = ShareModelTestUtility.linkContent
    XCTAssertEqual(content.contentURL, ShareModelTestUtility.contentURL)
    XCTAssertEqual(content.hashtag, ShareModelTestUtility.hashtag)
    XCTAssertEqual(content.peopleIDs, ShareModelTestUtility.peopleIDs)
    XCTAssertEqual(content.placeID, ShareModelTestUtility.placeID)
    XCTAssertEqual(content.ref, ShareModelTestUtility.ref)
    XCTAssertEqual(content.quote, ShareModelTestUtility.quote)
  }

  func testCopy() throws {
    let content = ShareModelTestUtility.linkContent
    let contentCopy = try XCTUnwrap(
      content.copy() as? ShareLinkContent,
      "Unable to make a copy or casting to 'ShareLinkContent' failed"
    )
    XCTAssertEqual(content, contentCopy)
    XCTAssertNotIdentical(content, contentCopy)
  }

  func testCoding() {
    let content = ShareModelTestUtility.linkContent
    let data = NSKeyedArchiver.archivedData(withRootObject: content)
    let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
    unarchiver.requiresSecureCoding = true
    let unarchivedObject = unarchiver.decodeObject(
      of: ShareLinkContent.self,
      forKey: NSKeyedArchiveRootObjectKey
    )
    XCTAssertEqual(unarchivedObject, content)
  }

  func testValidationWithValidContent() {
    XCTAssertNoThrow(
      try ShareUtility.validateShare(
        ShareModelTestUtility.linkContent,
        bridgeOptions: []
      )
    )
  }
}

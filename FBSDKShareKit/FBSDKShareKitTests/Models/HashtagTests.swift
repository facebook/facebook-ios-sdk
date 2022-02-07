/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

final class HashtagTests: XCTestCase {

  func testValidHashtag() {
    let hashtag = Hashtag("#ValidHashtag")
    XCTAssertTrue(hashtag.isValid)
  }

  func testInvalidHashtagWithSpaces() {
    let leadingSpace = Hashtag(" #LeadingSpaceIsInvalid")
    XCTAssertFalse(leadingSpace.isValid)

    let trailingspace = Hashtag("#TrailingSpaceIsInvalid ")
    XCTAssertFalse(trailingspace.isValid)

    let embeddedSpace = Hashtag("#No spaces in hashtags")
    XCTAssertFalse(embeddedSpace.isValid)
  }

  func testEquatabilityOfCopy() {
    let hashtag = Hashtag("#ToCopy")
    let copy = Hashtag("#ToCopy")
    XCTAssertEqual(copy, hashtag)
    XCTAssertNotIdentical(copy, hashtag)
    copy.stringRepresentation = "#ModifiedCopy"
    XCTAssertNotEqual(copy, hashtag)
    let notCopied = hashtag
    notCopied.stringRepresentation = "#ModifiedOriginal"
    XCTAssertEqual(hashtag.stringRepresentation, "#ModifiedOriginal")
    XCTAssertEqual(notCopied, hashtag)
    XCTAssertIdentical(notCopied, hashtag)
  }

  func testCoding() throws {
    let hashtag = Hashtag("#Encoded")
    let data = NSKeyedArchiver.archivedData(withRootObject: hashtag)
    let unarchivedHashtag = try NSKeyedUnarchiver.unarchivedObject(ofClass: Hashtag.self, from: data)
    XCTAssertEqual(hashtag, unarchivedHashtag)
  }
}

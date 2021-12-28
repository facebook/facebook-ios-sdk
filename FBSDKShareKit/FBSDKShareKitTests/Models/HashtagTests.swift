/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

class HashtagTests: XCTestCase {

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

  func testCopy() {
    let hashtag = Hashtag("#ToCopy")
    let copied = hashtag.copy() as! Hashtag // swiftlint:disable:this force_cast
    XCTAssertEqual(copied, hashtag)
    XCTAssertNotIdentical(copied, hashtag)
    copied.stringRepresentation = "#ModifiedCopy"
    XCTAssertNotEqual(copied, hashtag)
    let notCopied = hashtag
    notCopied.stringRepresentation = "#ModifiedOriginal"
    XCTAssertEqual(hashtag.stringRepresentation, "#ModifiedOriginal")
    XCTAssertEqual(notCopied, hashtag)
    XCTAssertIdentical(notCopied, hashtag)
  }

  func testCoding() throws {
    let hashtag = Hashtag("#Encoded")
    let data = NSKeyedArchiver.archivedData(withRootObject: hashtag)
    if #available(iOS 11.0, *) {
      let unarchivedHashtag = try NSKeyedUnarchiver.unarchivedObject(ofClass: Hashtag.self, from: data)
      XCTAssertEqual(hashtag, unarchivedHashtag)
    } else {
      let unarchivedHashtag = NSKeyedUnarchiver.unarchiveObject(with: data)
      XCTAssertEqual(hashtag, unarchivedHashtag as! Hashtag) // swiftlint:disable:this force_cast
    }
  }
}

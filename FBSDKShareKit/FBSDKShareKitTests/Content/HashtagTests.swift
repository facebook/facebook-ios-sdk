/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKShareKit

import XCTest

final class HashtagTests: XCTestCase {

  let validRawHashtag = "#ValidHashtag"
  var hashtag: Hashtag! // swiftlint:disable:this implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()
    hashtag = Hashtag(validRawHashtag)
  }

  override func tearDown() {
    hashtag = nil
    super.tearDown()
  }

  func testValidHashtag() {
    XCTAssertTrue(hashtag.isValid, .validHashtag)
  }

  func testInvalidHashtagWithSpaces() {
    let leadingSpace = Hashtag(" #LeadingSpaceIsInvalid")
    XCTAssertFalse(leadingSpace.isValid, .invalidHashtag)

    let trailingspace = Hashtag("#TrailingSpaceIsInvalid ")
    XCTAssertFalse(trailingspace.isValid, .invalidHashtag)

    let embeddedSpace = Hashtag("#No spaces in hashtags")
    XCTAssertFalse(embeddedSpace.isValid, .invalidHashtag)
  }

  func testStringRepresentation() {
    XCTAssertEqual(hashtag.stringRepresentation, validRawHashtag, .stringRepresentation)
  }

  func testDescription() {
    XCTAssertEqual(hashtag.description, validRawHashtag, .validDescription)

    let invalidRawHashtag = "# InvalidHashtag"
    hashtag = Hashtag(invalidRawHashtag)
    XCTAssertEqual(hashtag.description, "Invalid hashtag '\(invalidRawHashtag)'", .invalidDescription)
  }

  func testHashability() {
    XCTAssertEqual(hashtag.hash, validRawHashtag.hash, .hashIsStringHash)
  }

  func testEquatability() {
    let hashtag = Hashtag("#ToCopy")
    let copy = Hashtag("#ToCopy")
    XCTAssertEqual(copy, hashtag, .equalStrings)

    copy.stringRepresentation = "#ModifiedCopy"
    XCTAssertNotEqual(copy, hashtag, .unequalStrings)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let validHashtag = "A hashtag with a valid string should be considered valid"
  static let invalidHashtag = "A hashtag must start with an octothorp and contain no spaces"

  static let stringRepresentation = "A hashtag's string representation should be the provided raw string"

  static let validDescription = "An valid hashtag's description should be its raw string representation"
  static let invalidDescription = """
    An invalid hashtag's description should be a string indicating the invalidity and containg \
    the invalid hashtag string
    """

  static let hashIsStringHash = "The hash value of a hashtag should be the hash of its raw string"

  static let equalStrings = "Hashtags with equal strings should be considered equal"
  static let unequalStrings = "Hashtags with unequal strings should be considered unequal"
}

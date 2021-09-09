// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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

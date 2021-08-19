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

import FBSDKShareKit
import XCTest

class ShareMediaContentTests: XCTestCase {

  func testProperties() {
    let mediaContentMedia = ShareModelTestUtility.mediaContent().media
    let media = ShareModelTestUtility.media() as? [ShareMedia] ?? []

    for (item1, item2) in zip(media, mediaContentMedia) {
      if let photo1 = item1 as? SharePhoto, let photo2 = item2 as? SharePhoto {
        XCTAssertEqual(photo1, photo2)
      } else if let video1 = item1 as? ShareVideo, let video2 = item2 as? ShareVideo {
        XCTAssertEqual(video1, video2)
      } else {
        XCTFail("Unexpected type implementing the ShareMedia protocol. Item1: \(item1), Item2: \(item2)")
      }
    }
  }

  func testCopy() {
    guard
      let content = ShareModelTestUtility.mediaContent(),
      let contentCopy = content.copy() as? ShareMediaContent
    else {
      XCTFail("Unable to make a copy or casting to 'ShareMediaContent' failed")
      return
    }
    XCTAssertEqual(content, contentCopy)
    XCTAssertNotIdentical(content, contentCopy)
  }

  func testCoding() throws {
    guard
      let content = ShareModelTestUtility.mediaContent().media.first as? ShareVideo
    else {
      XCTFail("unable to get an item or casting to 'ShareVideo' failed")
      return
    }

    var unarchivedContent: ShareVideo?
    var data: Data

    if #available(iOS 11.0, *) {
      // NSKeyedUnarchiver.unarchiveObject(with:) is deprecated in iOS 12. This new version is available from iOS 11.
      data = try NSKeyedArchiver.archivedData(withRootObject: content, requiringSecureCoding: true)
      unarchivedContent = try NSKeyedUnarchiver.unarchivedObject(ofClass: ShareVideo.self, from: data)
    } else {
      data = NSKeyedArchiver.archivedData(withRootObject: content)
      unarchivedContent = NSKeyedUnarchiver.unarchiveObject(with: data) as? ShareVideo
    }

    guard let unarchivedContent = unarchivedContent else {
      XCTFail("Unable to unarchive or casting to 'ShareVideo' failed")
      return
    }

    XCTAssertEqual(unarchivedContent, content)
  }
}

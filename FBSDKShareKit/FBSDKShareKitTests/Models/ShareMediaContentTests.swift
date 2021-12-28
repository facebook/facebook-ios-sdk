/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKShareKit
import XCTest

class ShareMediaContentTests: XCTestCase {

  func testProperties() {
    let mediaContentMedia = ShareModelTestUtility.mediaContent.media
    let media = ShareModelTestUtility.media

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
    let content = ShareModelTestUtility.mediaContent
    guard let contentCopy = content.copy() as? ShareMediaContent else {
      XCTFail("Unable to make a copy or casting to 'ShareMediaContent' failed")
      return
    }
    XCTAssertEqual(content, contentCopy)
    XCTAssertNotIdentical(content, contentCopy)
  }

  func testCoding() throws {
    guard
      let content = ShareModelTestUtility.mediaContent.media.first as? ShareVideo
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

/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKShareKit
import XCTest

final class ShareMediaContentTests: XCTestCase {

  func testProperties() {
    let mediaContentMedia = ShareModelTestUtility.mediaContent.media
    let media = ShareModelTestUtility.media

    for (item1, item2) in zip(media, mediaContentMedia) {
      if let photo1 = item1 as? SharePhoto,
         let photo2 = item2 as? SharePhoto {
        XCTAssertEqual(photo1, photo2)
      } else if let video1 = item1 as? ShareVideo,
                let video2 = item2 as? ShareVideo {
        XCTAssertEqual(video1, video2)
      } else {
        XCTFail("Unexpected type implementing the ShareMedia protocol. Item1: \(item1), Item2: \(item2)")
      }
    }
  }

  func testCoding() throws {
    let media = try XCTUnwrap(ShareModelTestUtility.mediaContent)
    let data = try NSKeyedArchiver.archivedData(withRootObject: media, requiringSecureCoding: true)
    let unarchivedMedia = try XCTUnwrap(
      NSKeyedUnarchiver.unarchivedObject(ofClass: ShareMediaContent.self, from: data)
    )

    XCTAssertEqual(unarchivedMedia.contentURL, media.contentURL)
    XCTAssertEqual(unarchivedMedia.hashtag, media.hashtag)
    XCTAssertEqual(unarchivedMedia.peopleIDs, media.peopleIDs)
    XCTAssertEqual(unarchivedMedia.media.count, media.media.count)
    XCTAssertEqual(unarchivedMedia.placeID, media.placeID)
    XCTAssertEqual(unarchivedMedia.ref, media.ref)
    XCTAssertEqual(unarchivedMedia.pageID, media.pageID)
  }
}

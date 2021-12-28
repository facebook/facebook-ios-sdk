/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import XCTest

class ShareVideoTests: XCTestCase {

  func testImageProperties() {
    let video = ShareModelTestUtility.videoWithPreviewPhoto

    XCTAssertEqual(video.videoURL, ShareModelTestUtility.videoURL)
    XCTAssertEqual(video.previewPhoto, ShareModelTestUtility.photoWithImageURL)
  }

  func testCopy() throws {
    let video = ShareModelTestUtility.video
    guard let videoCopy = video.copy() as? ShareVideo else {
      XCTFail("unable to make a copy of 'ShareVideo'")
      return
    }

    XCTAssertEqual(videoCopy, video)
  }

  func testCoding() throws {
    let video = ShareModelTestUtility.videoWithPreviewPhoto

    var unarchivedContent: ShareVideo?
    var data: Data

    if #available(iOS 11.0, *) {
      // NSKeyedUnarchiver.unarchiveObject(with:) is deprecated in iOS 12. This new version is available from iOS 11.
      data = try NSKeyedArchiver.archivedData(withRootObject: video, requiringSecureCoding: true)
      unarchivedContent = try NSKeyedUnarchiver.unarchivedObject(ofClass: ShareVideo.self, from: data)
    } else {
      data = NSKeyedArchiver.archivedData(withRootObject: video)
      unarchivedContent = NSKeyedUnarchiver.unarchiveObject(with: data) as? ShareVideo
    }

    guard let unarchivedContent = unarchivedContent else {
      XCTFail("Unable to unarchive or casting to 'ShareVideo' failed")
      return
    }

    XCTAssertEqual(unarchivedContent, video)
  }
}

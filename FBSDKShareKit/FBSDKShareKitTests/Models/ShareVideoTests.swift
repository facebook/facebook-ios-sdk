/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import XCTest

final class ShareVideoTests: XCTestCase {

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

    let data = try NSKeyedArchiver.archivedData(withRootObject: video, requiringSecureCoding: true)
    let unarchivedContent = try NSKeyedUnarchiver.unarchivedObject(ofClass: ShareVideo.self, from: data)

    guard let unarchivedContent = unarchivedContent else {
      XCTFail("Unable to unarchive or casting to 'ShareVideo' failed")
      return
    }

    XCTAssertEqual(unarchivedContent, video)
  }
}

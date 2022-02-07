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

  func testCoding() throws {
    let video = ShareModelTestUtility.videoWithPreviewPhoto

    let data = try NSKeyedArchiver.archivedData(withRootObject: video, requiringSecureCoding: true)
    let unarchivedContent = try XCTUnwrap(
      NSKeyedUnarchiver.unarchivedObject(ofClass: ShareVideo.self, from: data)
    )

    XCTAssertEqual(unarchivedContent.data, video.data)
    XCTAssertEqual(unarchivedContent.videoAsset, video.videoAsset)
    XCTAssertEqual(unarchivedContent.videoURL, video.videoURL)
    XCTAssertEqual(unarchivedContent.previewPhoto?.image, video.previewPhoto?.image)
    XCTAssertEqual(unarchivedContent.previewPhoto?.imageURL, video.previewPhoto?.imageURL)
    XCTAssertEqual(unarchivedContent.previewPhoto?.photoAsset, video.previewPhoto?.photoAsset)
    XCTAssertEqual(unarchivedContent.previewPhoto?.isUserGenerated, video.previewPhoto?.isUserGenerated)
    XCTAssertEqual(unarchivedContent.previewPhoto?.caption, video.previewPhoto?.caption)
  }
}

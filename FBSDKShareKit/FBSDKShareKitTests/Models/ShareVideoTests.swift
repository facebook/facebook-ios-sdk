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
}

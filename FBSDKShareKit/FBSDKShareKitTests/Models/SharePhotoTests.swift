/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

final class SharePhotoTests: XCTestCase {

  func testImageProperties() {
    let photo = ShareModelTestUtility.photoWithImage
    XCTAssertEqual(photo.image, ShareModelTestUtility.photoImage)
    XCTAssertNil(photo.imageURL)
    XCTAssertEqual(photo.isUserGenerated, ShareModelTestUtility.isPhotoUserGenerated)
  }

  func testImageURLProperties() {
    let photo = ShareModelTestUtility.photoWithImageURL
    XCTAssertNil(photo.image)
    XCTAssertEqual(photo.imageURL, ShareModelTestUtility.photoImageURL)
    XCTAssertEqual(photo.isUserGenerated, ShareModelTestUtility.isPhotoUserGenerated)
  }
}

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

  func testCoding() throws {
    let photo = ShareModelTestUtility.photoWithImageURL
    let data = NSKeyedArchiver.archivedData(withRootObject: photo)
    let unarchivedPhoto = try XCTUnwrap(
      NSKeyedUnarchiver.unarchivedObject(ofClass: SharePhoto.self, from: data)
    )

    XCTAssertEqual(unarchivedPhoto.isUserGenerated, photo.isUserGenerated)
    XCTAssertEqual(unarchivedPhoto.image, photo.image)
    XCTAssertEqual(unarchivedPhoto.imageURL, photo.imageURL)
    XCTAssertEqual(unarchivedPhoto.photoAsset, photo.photoAsset)
    XCTAssertEqual(unarchivedPhoto.caption, photo.caption)
  }
}

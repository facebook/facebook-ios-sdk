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

  func testImageCopy() {
    let photo = ShareModelTestUtility.photoWithImage
    let copy = ShareModelTestUtility.photoWithImage
    XCTAssertEqual(copy, photo)
  }

  func testImageURLCopy() {
    let photo = ShareModelTestUtility.photoWithImageURL
    let copy = ShareModelTestUtility.photoWithImageURL
    XCTAssertEqual(copy, photo)
  }

  func testInequality() throws {
    let photo1 = ShareModelTestUtility.photoWithImage
    let photo2 = ShareModelTestUtility.photoWithImageURL
    XCTAssertNotEqual(photo1.hash, photo2.hash)
    XCTAssertNotEqual(photo1, photo2)

    let photo3 = ShareModelTestUtility.photoWithImageURL
    XCTAssertEqual(photo2.hash, photo3.hash)
    XCTAssertEqual(photo2, photo3)
  }

  func testCoding() throws {
    let photo = ShareModelTestUtility.photoWithImageURL
    let data = NSKeyedArchiver.archivedData(withRootObject: photo)
    let unarchivedPhoto = try XCTUnwrap(
      NSKeyedUnarchiver.unarchivedObject(ofClass: SharePhoto.self, from: data)
    )
    XCTAssertEqual(unarchivedPhoto, photo)
  }
}

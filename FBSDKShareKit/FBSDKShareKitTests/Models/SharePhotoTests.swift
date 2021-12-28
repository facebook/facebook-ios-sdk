/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

class SharePhotoTests: XCTestCase {

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
    XCTAssertEqual(photo.copy() as? SharePhoto, photo)
  }

  func testImageURLCopy() {
    let photo = ShareModelTestUtility.photoWithImageURL
    XCTAssertEqual(photo.copy() as? SharePhoto, photo)
  }

  func testInequality() throws {
    let photo1 = ShareModelTestUtility.photoWithImage
    let photo2 = ShareModelTestUtility.photoWithImageURL
    XCTAssertNotEqual(photo1.hash, photo2.hash)
    XCTAssertNotEqual(photo1, photo2)

    let photo3 = try XCTUnwrap(photo2.copy() as? SharePhoto)
    XCTAssertEqual(photo2.hash, photo3.hash)
    XCTAssertEqual(photo2, photo3)
    photo3.isUserGenerated = !photo2.isUserGenerated
    XCTAssertNotEqual(photo2.hash, photo3.hash)
    XCTAssertNotEqual(photo2, photo3)
  }

  func testCoding() throws {
    let photo = ShareModelTestUtility.photoWithImageURL
    let data = NSKeyedArchiver.archivedData(withRootObject: photo)
    let unarchivedPhoto: SharePhoto
    if #available(iOS 11.0, *) {
      unarchivedPhoto = try XCTUnwrap(
        NSKeyedUnarchiver.unarchivedObject(ofClass: SharePhoto.self, from: data)
      )
    } else {
      unarchivedPhoto = try XCTUnwrap(
        NSKeyedUnarchiver.unarchiveObject(with: data) as? SharePhoto
      )
    }
    XCTAssertEqual(unarchivedPhoto, photo)
  }
}

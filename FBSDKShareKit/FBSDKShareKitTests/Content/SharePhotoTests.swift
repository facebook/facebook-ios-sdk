/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKShareKit
import Photos
import TestTools
import XCTest

final class SharePhotoTests: XCTestCase {
  private enum Assumptions {
    static let imageSource = "A photo with an image source should only have a data source"
    static let assetSource = "A photo with an asset source should only have an asset source"
    static let urlSource = "A photo with a URL source should only have a URL source"
    static let clearedSources = "Changing a photo source should clear other sources"
  }

  var photo: SharePhoto! // swiftlint:disable:this implicitly_unwrapped_optional

  override func tearDown() {
    photo = nil
    super.tearDown()
  }

  func testCreatingWithImage() {
    photo = SharePhoto(image: UIImage(), isUserGenerated: true)
    XCTAssertNotNil(photo.image, Assumptions.imageSource)
    XCTAssertNil(photo.photoAsset, Assumptions.imageSource)
    XCTAssertNil(photo.imageURL, Assumptions.imageSource)
  }

  func testCreatingWithAsset() {
    photo = SharePhoto(photoAsset: PHAsset(), isUserGenerated: true)
    XCTAssertNotNil(photo.photoAsset, Assumptions.assetSource)
    XCTAssertNil(photo.image, Assumptions.assetSource)
    XCTAssertNil(photo.imageURL, Assumptions.assetSource)
  }

  func testCreatingWithURL() {
    photo = SharePhoto(imageURL: SampleURLs.valid, isUserGenerated: true)
    XCTAssertNotNil(photo.imageURL, Assumptions.urlSource)
    XCTAssertNil(photo.image, Assumptions.urlSource)
    XCTAssertNil(photo.photoAsset, Assumptions.urlSource)
  }

  func testChangingSource() {
    photo = SharePhoto(image: UIImage(), isUserGenerated: true)

    photo.photoAsset = PHAsset()
    XCTAssertNil(photo.image, Assumptions.clearedSources)

    photo.imageURL = SampleURLs.valid
    XCTAssertNil(photo.photoAsset, Assumptions.clearedSources)

    photo.image = UIImage()
    XCTAssertNil(photo.imageURL, Assumptions.clearedSources)
  }
}

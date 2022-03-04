/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKShareKit

import Photos
import TestTools
import XCTest

final class SharePhotoTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var photo: SharePhoto!
  var errorFactory: TestErrorFactory!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    SharePhoto.unconfigure()
    errorFactory = TestErrorFactory()
    SharePhoto.configure(with: .init(errorFactory: errorFactory))
  }

  override func tearDown() {
    errorFactory = nil
    SharePhoto.unconfigure()
    photo = nil

    super.tearDown()
  }

  func testDefaultDependencies() throws {
    SharePhoto.unconfigure()

    let dependencies = try SharePhoto.getDependencies()
    XCTAssertTrue(dependencies.errorFactory is ErrorFactory, .usesConcreteErrorFactoryByDefault)
  }

  func testCustomDependencies() throws {
    let dependencies = try SharePhoto.getDependencies()
    XCTAssertIdentical(dependencies.errorFactory, errorFactory, .usesCustomErrorFactory)
  }

  func testCreatingWithImage() {
    photo = SharePhoto(image: UIImage(), isUserGenerated: true)
    XCTAssertNotNil(photo.image, .hasOnlyImageSource)
    XCTAssertNil(photo.photoAsset, .hasOnlyImageSource)
    XCTAssertNil(photo.imageURL, .hasOnlyImageSource)
  }

  func testCreatingWithAsset() {
    photo = SharePhoto(photoAsset: PHAsset(), isUserGenerated: true)
    XCTAssertNotNil(photo.photoAsset, .hasOnlyAssetSource)
    XCTAssertNil(photo.image, .hasOnlyAssetSource)
    XCTAssertNil(photo.imageURL, .hasOnlyAssetSource)
  }

  func testCreatingWithURL() {
    photo = SharePhoto(imageURL: SampleURLs.valid, isUserGenerated: true)
    XCTAssertNotNil(photo.imageURL, .hasOnlyURLSource)
    XCTAssertNil(photo.image, .hasOnlyURLSource)
    XCTAssertNil(photo.photoAsset, .hasOnlyURLSource)
  }

  func testChangingSource() {
    photo = SharePhoto(image: UIImage(), isUserGenerated: true)

    photo.photoAsset = PHAsset()
    XCTAssertNil(photo.image, .otherSourcesClearedWhenChangingSource)

    photo.imageURL = SampleURLs.valid
    XCTAssertNil(photo.photoAsset, .otherSourcesClearedWhenChangingSource)

    photo.image = UIImage()
    XCTAssertNil(photo.imageURL, .otherSourcesClearedWhenChangingSource)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let usesConcreteErrorFactoryByDefault = """
    The default error factory dependency should be a concrete ErrorFactory
    """
  static let usesCustomErrorFactory = "The error factory dependency should be configurable"

  static let hasOnlyImageSource = "A photo with an image source should only have a data source"
  static let hasOnlyAssetSource = "A photo with an asset source should only have an asset source"
  static let hasOnlyURLSource = "A photo with a URL source should only have a URL source"
  static let otherSourcesClearedWhenChangingSource = "Changing a photo source should clear other sources"
}

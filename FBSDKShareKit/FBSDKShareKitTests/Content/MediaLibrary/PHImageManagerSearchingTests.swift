/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKShareKit
import Photos
import XCTest

final class PHImageManagerSearchingTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var imageManager: TestPHImageManager!
  var asset: PHAsset!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    imageManager = TestPHImageManager()
    asset = PHAsset()
  }

  override func tearDown() {
    imageManager = nil
    asset = nil

    super.tearDown()
  }

  func testFindImageRequest() throws {
    _ = try? imageManager.findImage(for: asset)

    XCTAssertIdentical(imageManager.requestImageAsset, asset, .forwardsCallToRequestImage)
    XCTAssertEqual(imageManager.requestImageTargetSize, PHImageManagerMaximumSize, .targetSizeIsMaximum)
    XCTAssertEqual(imageManager.requestImageContentMode, .default, .contentModeIsDefault)

    let options = try XCTUnwrap(imageManager.requestImageOptions, .forwardsCallToRequestImage)
    XCTAssertEqual(options.resizeMode, .exact, .resizeModeIsExact)
    XCTAssertEqual(options.deliveryMode, .highQualityFormat, .deliveryModeIsHighQualityFormat)
    XCTAssertTrue(options.isSynchronous, .imageRequestIsSynchronous)
  }

  func testFindImageFailure() {
    XCTAssertThrowsError(
      try imageManager.findImage(for: asset),
      .throwsErrorWhenImageNotAvailable
    ) { anyError in
      guard let error = anyError as? PHImageManagerSearchError else {
        return XCTFail(.throwsErrorWhenImageNotAvailable)
      }

      XCTAssertIdentical(error.asset, asset, .throwsErrorWhenImageNotAvailable)
    }
  }

  func testFindImageSuccess() throws {
    let expectedImage = UIImage()
    imageManager.stubbedRequestedImage = expectedImage

    var image: UIImage?
    XCTAssertNoThrow(
      image = try imageManager.findImage(for: asset),
      .returnsImageWhenAvailable
    )

    XCTAssertIdentical(image, expectedImage, .returnsImageWhenAvailable)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let forwardsCallToRequestImage = """
    A PHImageManager should forward image-finding requests to its image request method
    """
  static let targetSizeIsMaximum = "The maximum image size should be requested"
  static let contentModeIsDefault = "The default content mode should be requested"
  static let resizeModeIsExact = "The exact resize mode should be requested"
  static let deliveryModeIsHighQualityFormat = "The high quality format delivery mode should be requested"
  static let imageRequestIsSynchronous = "Image request calls should be synchronous"

  static let throwsErrorWhenImageNotAvailable = "An error should be thrown when an image is not available for an asset"
  static let returnsImageWhenAvailable = "An asset's image should be returned when available"
}

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

  // MARK: - Requesting images

  func testFindImageRequest() throws {
    _ = try? imageManager.fb_findImage(for: asset)

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
      try imageManager.fb_findImage(for: asset),
      .throwsErrorWhenImageNotAvailable
    ) { anyError in
      guard let error = anyError as? PHImageManager.MediaLibrarySearchError else {
        return XCTFail(.throwsErrorWhenImageNotAvailable)
      }

      XCTAssertIdentical(error.asset, asset, .throwsErrorWhenImageNotAvailable)
    }
  }

  func testFindImageSuccess() throws {
    let expectedImage = UIImage()
    imageManager.stubbedRequestImageImage = expectedImage

    var image: UIImage?
    XCTAssertNoThrow(
      image = try imageManager.fb_findImage(for: asset),
      .returnsImageWhenAvailable
    )

    XCTAssertIdentical(image, expectedImage, .returnsImageWhenAvailable)
  }

  // MARK: - Getting video URLs

  func testGetVideoURLRequest() throws {
    _ = try? imageManager.fb_getVideoURL(for: asset)

    XCTAssertIdentical(imageManager.requestAVAssetAsset, asset, .forwardsCallToRequestAVAsset)

    let options = try XCTUnwrap(imageManager.requestAVAssetOptions, .forwardsCallToRequestAVAsset)
    XCTAssertEqual(options.version, .current, .versionIsCurrent)
    XCTAssertEqual(options.deliveryMode, .automatic, .deliveryModeIsAutomatic)
    XCTAssertTrue(options.isNetworkAccessAllowed, .networkAccessAllowed)
  }

  func testGetVideoURLAssetFailure() {
    asset = .withLocalIdentifier

    XCTAssertThrowsError(
      try imageManager.fb_getVideoURL(for: asset),
      .throwsErrorWhenVideoURLAssetNotAvailable
    ) { anyError in
      guard let error = anyError as? PHImageManager.MediaLibrarySearchError else {
        return XCTFail(.throwsErrorWhenVideoURLAssetNotAvailable)
      }

      XCTAssertIdentical(error.asset, asset, .throwsErrorWhenVideoURLAssetNotAvailable)
    }
  }

  func testGetVideoURLFileFailure() {
    asset = .withLocalIdentifier
    imageManager.stubbedGetVideoURLAsset = AVURLAsset.remote

    XCTAssertThrowsError(
      try imageManager.fb_getVideoURL(for: asset),
      .throwsErrorWhenVideoURLAssetNotAvailable
    ) { anyError in
      guard let error = anyError as? PHImageManager.MediaLibrarySearchError else {
        return XCTFail(.throwsErrorWhenVideoURLAssetNotAvailable)
      }

      XCTAssertIdentical(error.asset, asset, .throwsErrorWhenVideoURLAssetNotAvailable)
    }
  }

  func testGetVideoURLIdentifierFailure() {
    asset = .withoutLocalIdentifier
    imageManager.stubbedGetVideoURLAsset = AVURLAsset.local

    XCTAssertThrowsError(
      try imageManager.fb_getVideoURL(for: asset),
      .throwsErrorWhenVideoURLIdentifierNotAvailable
    ) { anyError in
      guard let error = anyError as? PHImageManager.MediaLibrarySearchError else {
        return XCTFail(.throwsErrorWhenVideoURLIdentifierNotAvailable)
      }

      XCTAssertIdentical(error.asset, asset, .throwsErrorWhenVideoURLIdentifierNotAvailable)
    }
  }

  func testGetVideoURLSuccess() throws {
    asset = .withLocalIdentifier
    imageManager.stubbedGetVideoURLAsset = AVURLAsset.local

    var url: URL?
    XCTAssertNoThrow(
      url = try imageManager.fb_getVideoURL(for: asset),
      .returnsVideoURLWhenAvailable
    )

    let expectedURL = """
      assets-library://asset/asset.\(String.urlAssetPathExtension)?id=\(String.uuid)&ext=\(String.urlAssetPathExtension)
      """
    XCTAssertEqual(url?.absoluteString, expectedURL, .returnsVideoURLWhenAvailable)
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

  static let forwardsCallToRequestAVAsset = """
    A PHImageManager should forward video URL requests to its video asset request method
    """
  static let versionIsCurrent = "The version should be current"
  static let deliveryModeIsAutomatic = "The delivery mode should be automatic"
  static let networkAccessAllowed = "Network access should be allowed"

  static let throwsErrorWhenVideoURLAssetNotAvailable = """
    An error should be thrown when a URL asset is not available for a video asset
    """
  static let throwsErrorWhenVideoURLFileURLNotAvailable = """
    An error should be thrown when a file URL is not available for a video asset
    """
  static let throwsErrorWhenVideoURLIdentifierNotAvailable = """
    An error should be thrown when a local identifier is not available for a video asset
    """
  static let returnsVideoURLWhenAvailable = "A URL should be returned when available for a video asset"
}

// MARK: - Test Values

fileprivate extension String {
  static let uuid = UUID().uuidString
  static let localIdentifier = "\(uuid)/more-stuff"
  static let urlAssetPathExtension = "ext"
  static let urlAssetURL = "file:///somewhere/over.\(urlAssetPathExtension)"
}

fileprivate extension URL {
  // swiftlint:disable force_unwrapping
  static let video = URL(string: "https://facebook.com")!
  static let remote = URL(string: "https://facebook.com")!
  static let local = URL(string: "file:///local/video.\(String.urlAssetPathExtension)")!
  // swiftlint:enable force_unwrapping
}

fileprivate extension AVURLAsset {
  static let remote = AVURLAsset(url: .remote)
  static let local = AVURLAsset(url: .local)
}

fileprivate extension PHAsset {
  static let withLocalIdentifier: PHAsset = {
    let asset = TestPHAsset()
    asset.stubbedLocalIdentifier = .localIdentifier
    return asset
  }()

  static let withoutLocalIdentifier: PHAsset = {
    let asset = TestPHAsset()
    asset.stubbedLocalIdentifier = ""
    return asset
  }()
}

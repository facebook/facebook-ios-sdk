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

    errorFactory = TestErrorFactory()
    SharePhoto.setDependencies(.init(errorFactory: errorFactory))
  }

  override func tearDown() {
    errorFactory = nil
    SharePhoto.resetDependencies()
    photo = nil

    super.tearDown()
  }

  func testDefaultDependencies() throws {
    SharePhoto.resetDependencies()

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

  func testValidatingWithoutSource() {
    photo = SharePhoto()

    XCTAssertThrowsError(try photo.validate(options: []), .failsValidationWithoutSource) { error in
      guard let sdkError = error as? TestSDKError else {
        return XCTFail(.failsValidationWithoutSource)
      }

      XCTAssertEqual(sdkError.domain, ShareErrorDomain, .failsValidationWithoutSource)
      XCTAssertEqual(sdkError.name, "photo", .failsValidationWithoutSource)
      XCTAssertIdentical(sdkError.value as AnyObject, photo, .failsValidationWithoutSource)
      XCTAssertEqual(
        sdkError.message,
        "Must have an asset, image, or imageURL value.",
        .failsValidationWithoutSource
      )
      XCTAssertNil(sdkError.underlyingError, .failsValidationWithoutSource)
    }
  }

  func testPhotoImageURLValidationFailureWithoutURL() {
    photo = SharePhoto()

    XCTAssertThrowsError(
      try photo.validate(options: .photoImageURL),
      .failsPhotoImageURLOptionValidationWithoutURL
    ) { error in
      guard let sdkError = error as? TestSDKError else {
        return XCTFail(.failsPhotoImageURLOptionValidationWithoutURL)
      }

      XCTAssertEqual(sdkError.domain, ShareErrorDomain, .failsPhotoImageURLOptionValidationWithoutURL)
      XCTAssertEqual(sdkError.name, "photo", .failsPhotoImageURLOptionValidationWithoutURL)
      XCTAssertIdentical(sdkError.value as AnyObject, photo, .failsPhotoImageURLOptionValidationWithoutURL)
      XCTAssertEqual(
        sdkError.message,
        "imageURL is required.",
        .failsPhotoImageURLOptionValidationWithoutURL
      )
      XCTAssertNil(sdkError.underlyingError, .failsPhotoImageURLOptionValidationWithoutURL)
    }
  }

  func testPhotoImageURLValidationFailureWithoutFileURL() {
    photo = SharePhoto(imageURL: .localImage, isUserGenerated: true)

    XCTAssertThrowsError(
      try photo.validate(options: .photoImageURL),
      .failsPhotoImageURLOptionValidationWithoutRemoteURL
    ) { error in
      guard let sdkError = error as? TestSDKError else {
        return XCTFail(.failsPhotoImageURLOptionValidationWithoutRemoteURL)
      }

      XCTAssertEqual(sdkError.domain, ShareErrorDomain, .failsPhotoImageURLOptionValidationWithoutRemoteURL)
      XCTAssertEqual(sdkError.name, "imageURL", .failsPhotoImageURLOptionValidationWithoutRemoteURL)
      XCTAssertEqual(sdkError.value as? URL, .localImage, .failsPhotoImageURLOptionValidationWithoutRemoteURL)
      XCTAssertEqual(
        sdkError.message,
        "Cannot refer to a local file resource.",
        .failsPhotoImageURLOptionValidationWithoutRemoteURL
      )
      XCTAssertNil(sdkError.underlyingError, .failsPhotoImageURLOptionValidationWithoutRemoteURL)
    }
  }

  func testPhotoImageURLValidationSuccess() {
    photo = SharePhoto(imageURL: .remoteImage, isUserGenerated: true)
    XCTAssertNoThrow(try photo.validate(options: .photoImageURL), .passesPhotoImageURLOptionValidation)
  }

  func testAssetValidationFailureWithoutImageMediaType() {
    let asset = TestPHAsset()
    photo = SharePhoto(photoAsset: asset, isUserGenerated: true)

    XCTAssertThrowsError(
      try photo.validate(options: []),
      .failsAssetValidationWithoutImageMediaType
    ) { error in
      guard let sdkError = error as? TestSDKError else {
        return XCTFail(.failsAssetValidationWithoutImageMediaType)
      }

      XCTAssertEqual(sdkError.domain, ShareErrorDomain, .failsAssetValidationWithoutImageMediaType)
      XCTAssertEqual(sdkError.name, "photoAsset", .failsAssetValidationWithoutImageMediaType)
      XCTAssertIdentical(sdkError.value as AnyObject, asset, .failsAssetValidationWithoutImageMediaType)
      XCTAssertEqual(
        sdkError.message,
        "Must refer to a photo or other static image.",
        .failsAssetValidationWithoutImageMediaType
      )
      XCTAssertNil(sdkError.underlyingError, .failsAssetValidationWithoutImageMediaType)
    }
  }

  func testAssetValidationSuccess() {
    let asset = TestPHAsset()
    asset.stubbedMediaType = .image
    photo = SharePhoto(photoAsset: asset, isUserGenerated: true)

    XCTAssertNoThrow(try photo.validate(options: []), .passesAssetValidation)
  }

  func testURLValidationFailure() {
    photo = SharePhoto(imageURL: .remoteImage, isUserGenerated: true)

    XCTAssertThrowsError(
      try photo.validate(options: []),
      .failsURLValidationWithoutFileURL
    ) { error in
      guard let sdkError = error as? TestSDKError else {
        return XCTFail(.failsURLValidationWithoutFileURL)
      }

      XCTAssertEqual(sdkError.domain, ShareErrorDomain, .failsURLValidationWithoutFileURL)
      XCTAssertEqual(sdkError.name, "imageURL", .failsURLValidationWithoutFileURL)
      XCTAssertEqual(sdkError.value as? URL, .remoteImage, .failsURLValidationWithoutFileURL)
      XCTAssertEqual(
        sdkError.message,
        "Must refer to a local file resource.",
        .failsURLValidationWithoutFileURL
      )
      XCTAssertNil(sdkError.underlyingError, .failsURLValidationWithoutFileURL)
    }
  }

  func testURLValidationSuccess() {
    photo = SharePhoto(imageURL: .localImage, isUserGenerated: true)
    XCTAssertNoThrow(try photo.validate(options: []), .passesURLValidation)
  }

  func testImageValidation() {
    let image = UIImage()
    photo = SharePhoto(image: image, isUserGenerated: true)
    XCTAssertNoThrow(try photo.validate(options: []), .passesImageValidation)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let usesConcreteErrorFactoryByDefault = """
    The default error factory dependency should be a concrete ErrorFactory
    """
  static let usesCustomErrorFactory = "The error factory dependency should be configurable"

  static let hasOnlyImageSource = "A photo with an image source should only have an image source"
  static let hasOnlyAssetSource = "A photo with an asset source should only have an asset source"
  static let hasOnlyURLSource = "A photo with a URL source should only have a URL source"
  static let otherSourcesClearedWhenChangingSource = "Changing a photo source should clear other sources"

  static let failsValidationWithoutSource = "Validating a photo without a source should throw an error"
  static let failsPhotoImageURLOptionValidationWithoutURL = """
    Validating a photo with the image photo URL option should fail without a URL
    """
  static let failsPhotoImageURLOptionValidationWithoutRemoteURL = """
    Validating a photo with the image photo URL option should fail without a remote URL
    """
  static let passesPhotoImageURLOptionValidation = """
    Validating a photo with the image photo URL option should pass with a file URL
    """
  static let failsAssetValidationWithoutImageMediaType = """
    Validating an asset photo without the image media type should throw an error
    """
  static let passesAssetValidation = "Validating an asset photo with the image media type should pass"
  static let failsURLValidationWithoutFileURL = "Validating a URL photo should fail without a file URL"
  static let passesURLValidation = "Validating a URL photo should pass with a file URL"
  static let passesImageValidation = "Validating an image photo should pass"
}

// MARK: - Test Values

fileprivate extension URL {
  // swiftlint:disable force_unwrapping
  static let remoteImage = URL(string: "https://facebook.com/myPhoto.png")!
  static let localImage = URL(string: "file:///Users/anyone/myPhoto.png")!
  // swiftlint:enable force_unwrapping
}

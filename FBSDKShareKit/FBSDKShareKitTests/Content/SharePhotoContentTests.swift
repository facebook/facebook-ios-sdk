/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKShareKit

import FBSDKCoreKit
import Photos
import XCTest

final class SharePhotoContentTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var content: SharePhotoContent!
  var imageFinder: TestMediaLibrarySearcher!
  var validator: TestShareUtility.Type!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    imageFinder = TestMediaLibrarySearcher()
    validator = TestShareUtility.self
    validator.reset()

    SharePhotoContent.setDependencies(
      .init(
        imageFinder: imageFinder,
        validator: TestShareUtility.self
      )
    )
  }

  override func tearDown() {
    imageFinder = nil
    validator.reset()
    validator = nil
    SharePhotoContent.resetDependencies()
    content = nil

    super.tearDown()
  }

  func testDefaultDependencies() throws {
    SharePhotoContent.resetDependencies()

    let dependencies = try SharePhotoContent.getDependencies()
    XCTAssertIdentical(dependencies.imageFinder as AnyObject, PHImageManager.default(), .usesPHImageManagerByDefault)
    XCTAssertTrue(dependencies.validator is _ShareUtility.Type, .usesShareUtilityByDefault)
  }

  func testCustomDependencies() throws {
    let dependencies = try SharePhotoContent.getDependencies()
    XCTAssertIdentical(dependencies.imageFinder as AnyObject, imageFinder, .usesCustomImageFinder)
    XCTAssertTrue(dependencies.validator is TestShareUtility.Type, .usesCustomShareValidator)
  }

  func testProperties() {
    let photos = makeSamplePhotos()
    content = makeSamplePhotoContent(photos: photos)

    XCTAssertEqual(content.contentURL, .content)
    XCTAssertEqual(content.peopleIDs, [.person1, .person2])
    XCTAssertEqual(content.placeID, .place)
    XCTAssertEqual(content.ref, .ref)

    XCTAssertEqual(content.photos.count, photos.count)
    zip(content.photos, photos).forEach { photo1, photo2 in
      XCTAssertEqual(photo1.imageURL, photo2.imageURL)
      XCTAssertEqual(photo1.isUserGenerated, photo2.isUserGenerated)
    }
  }

  func testValidationWithValidContent() {
    content = makeSamplePhotoContent(photos: [.regularImage])

    XCTAssertNoThrow(try content.validate(options: []))
    XCTAssertEqual(validator.validateArrayArray as? [SharePhoto], content.photos, .validationValidatesPhotos)
    XCTAssertEqual(validator.validateArrayMinCount, 1, .validationValidatesPhotos)
    XCTAssertEqual(validator.validateArrayMaxCount, 10, .validationValidatesPhotos)
    XCTAssertEqual(validator.validateArrayName, "photos", .validationValidatesPhotos)
  }

  func testValidationWithoutPhotos() {
    validator.validateArrayShouldThrow = true
    content = SharePhotoContent()

    XCTAssertThrowsError(try content.validate(options: []), .validationValidatesPhotos)
    XCTAssertEqual(validator.validateArrayArray as? [SharePhoto], content.photos, .validationValidatesPhotos)
    XCTAssertEqual(validator.validateArrayMinCount, 1, .validationValidatesPhotos)
    XCTAssertEqual(validator.validateArrayMaxCount, 10, .validationValidatesPhotos)
    XCTAssertEqual(validator.validateArrayName, "photos", .validationValidatesPhotos)
  }

  func testBridgeParameters() throws {
    let photos = makeSamplePhotos()
    content = makeSamplePhotoContent(photos: photos)
    imageFinder.stubbedFindImageImage = .forAsset

    let parameters = content.addParameters([:], options: [])

    let parameterPhotos = try XCTUnwrap(parameters["photos"] as? [UIImage], .imagesAreAddedToParameters)
    XCTAssertEqual(parameterPhotos.count, 3, .imagesAreAddedToParameters)

    let localImageData = UIImage.local.jpegData(compressionQuality: 1)
    XCTAssertTrue(
      parameterPhotos.contains { $0.jpegData(compressionQuality: 1) == localImageData },
      .imagesAreAddedToParameters
    )
    XCTAssertTrue(parameterPhotos.contains(.generated), .imagesAreAddedToParameters)
    XCTAssertTrue(parameterPhotos.contains(.forAsset), .imagesAreAddedToParameters)
    XCTAssertIdentical(imageFinder.findImageAsset, PHAsset.sample, .searchesForPHAssetImages)
  }

  // MARK: - Helpers

  private func makeSamplePhotoContent(photos: [SharePhoto]) -> SharePhotoContent {
    let content = SharePhotoContent()
    content.contentURL = .content
    content.peopleIDs = [.person1, .person2]
    content.photos = photos
    content.placeID = .place
    content.ref = .ref
    return content
  }

  private func makeSamplePhotos() -> [SharePhoto] {
    [
      .asset,
      .localURL,
      .remoteURL,
      .regularImage,
    ]
  }
}

// swiftformat:disable extensionaccesscontrol

// MARK: - Assumptions

fileprivate extension String {
  static let usesPHImageManagerByDefault = "The default image finder dependency should be the default PHImageManager"
  static let usesShareUtilityByDefault = "The default share validator dependency should be the _ShareUtility type"
  static let usesCustomImageFinder = "The image finder dependency should be configurable"
  static let usesCustomShareValidator = "The share validator dependency should be configurable"

  static let validationValidatesPhotos = """
    Validating a share photo content should validate its photos using its validator
    """

  static let imagesAreAddedToParameters = """
    Adding bridge parameters for share photo content should add images for all photos except those with remote URLs
    """
  static let searchesForPHAssetImages = """
    PHAsset images for bridge parameters should be found through the photo library searcher
    """
}

// MARK: - Test Values

fileprivate extension SharePhoto {
  static let asset = SharePhoto(photoAsset: .sample, isUserGenerated: true)
  static let localURL = SharePhoto(imageURL: .localImage, isUserGenerated: true)
  static let remoteURL = SharePhoto(imageURL: .remoteImage, isUserGenerated: true)
  static let regularImage = SharePhoto(image: .generated, isUserGenerated: true)
}

fileprivate extension URL {
  // swiftlint:disable force_unwrapping
  static let remoteImage = URL(string: "https://fbstatic-a.akamaihd.net/rsrc.php/v2/yC/r/YRwxe7CPWSs.png")!
  static let localImage = Bundle(for: SharePhotoContentTests.self)
    .url(forResource: "dog-or-muffin", withExtension: "jpeg")!
  static let content = URL(string: "https://developers.facebook.com/")!
  // swiftlint:enable force_unwrapped
}

fileprivate extension UIImage {
  static let generated = ShareModelTestUtility.generatedImage
  static let local = UIImage(contentsOfFile: URL.localImage.path)! // swiftlint:disable:this force_unwrapping
  static let forAsset = ShareModelTestUtility.generatedImage
}

fileprivate extension String {
  static let person1 = "1234"
  static let person2 = "5678"
  static let place = "9876"
  static let ref = "sample-ref"
}

fileprivate extension PHAsset {
  static let sample = PHAsset()
}

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
  var imageFinder: TestMediaLibrarySearcher!
  var validator: TestShareUtility.Type!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    imageFinder = TestMediaLibrarySearcher()
    validator = TestShareUtility.self
    validator.reset()

    SharePhotoContent.configure(
      with: .init(
        imageFinder: imageFinder,
        validator: TestShareUtility.self
      )
    )
  }

  override func tearDown() {
    imageFinder = nil
    validator.reset()
    validator = nil
    SharePhotoContent.unconfigure()

    super.tearDown()
  }

  func testDefaultDependencies() throws {
    SharePhotoContent.unconfigure()

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
    let content = ShareModelTestUtility.photoContent

    XCTAssertEqual(content.contentURL, ShareModelTestUtility.contentURL)
    XCTAssertEqual(content.peopleIDs, ShareModelTestUtility.peopleIDs)
    XCTAssertEqual(content.placeID, ShareModelTestUtility.placeID)
    XCTAssertEqual(content.ref, ShareModelTestUtility.ref)

    XCTAssertEqual(content.photos.count, ShareModelTestUtility.photos.count)
    zip(content.photos, ShareModelTestUtility.photos).forEach { photo1, photo2 in
      XCTAssertEqual(photo1.imageURL, photo2.imageURL)
      XCTAssertEqual(photo1.isUserGenerated, photo2.isUserGenerated)
    }
  }

  func testValidationWithValidContent() {
    let content = SharePhotoContent()
    content.contentURL = ShareModelTestUtility.contentURL
    content.peopleIDs = ShareModelTestUtility.peopleIDs
    content.photos = [ShareModelTestUtility.photoWithImage]
    content.placeID = ShareModelTestUtility.placeID
    content.ref = ShareModelTestUtility.ref

    XCTAssertNoThrow(try content.validate(options: []))
    XCTAssertEqual(validator.validateArrayArray as? [SharePhoto], content.photos, .validationValidatesPhotos)
    XCTAssertEqual(validator.validateArrayMinCount, 1, .validationValidatesPhotos)
    XCTAssertEqual(validator.validateArrayMaxCount, 6, .validationValidatesPhotos)
    XCTAssertEqual(validator.validateArrayName, "photos", .validationValidatesPhotos)
  }

  func testValidationWithoutPhotos() {
    validator.stubbedValidateArrayShouldThrow = true
    let content = SharePhotoContent()

    XCTAssertThrowsError(try content.validate(options: []), .validationValidatesPhotos)
    XCTAssertEqual(validator.validateArrayArray as? [SharePhoto], content.photos, .validationValidatesPhotos)
    XCTAssertEqual(validator.validateArrayMinCount, 1, .validationValidatesPhotos)
    XCTAssertEqual(validator.validateArrayMaxCount, 6, .validationValidatesPhotos)
    XCTAssertEqual(validator.validateArrayName, "photos", .validationValidatesPhotos)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let usesPHImageManagerByDefault = "The default image finder dependency should be the default PHImageManager"
  static let usesShareUtilityByDefault = "The default share validator dependency should be the _ShareUtility type"
  static let usesCustomImageFinder = "The image finder dependency should be configurable"
  static let usesCustomShareValidator = "The share validator dependency should be configurable"

  static let validationValidatesPhotos = """
    Validating a share photo content should validate its photos using its validator
    """
}

/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKShareKit

import FBSDKCoreKit
import TestTools
import UIKit
import XCTest

final class ShareVideoContentTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var content: ShareVideoContent!
  var validator: TestShareUtility.Type!
  var errorFactory: TestErrorFactory!
  var testError: TestSDKError!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    validator = TestShareUtility.self
    validator.reset()
    ShareVideoContent.setDependencies(.init(validator: TestShareUtility.self))

    errorFactory = TestErrorFactory()
    testError = TestSDKError(type: .unknown)
    errorFactory.stubbedError = testError
    ShareVideo.setDependencies(.init(errorFactory: errorFactory))

    content = .sample()
  }

  override func tearDown() {
    ShareVideo.resetDependencies()
    ShareVideoContent.resetDependencies()
    validator.reset()
    validator = nil
    errorFactory = nil
    testError = nil
    content = nil

    super.tearDown()
  }

  func testDefaultDependencies() throws {
    ShareVideoContent.resetDependencies()

    let dependencies = try ShareVideoContent.getDependencies()
    XCTAssertTrue(
      dependencies.validator is _ShareUtility.Type,
      .usesShareUtilityAsShareValidatorByDefault
    )
  }

  func testCustomDependencies() throws {
    let dependencies = try ShareVideoContent.getDependencies()
    XCTAssertTrue(dependencies.validator is TestShareUtility.Type, .usesCustomShareValidator)
  }

  func testProperties() {
    content = .sample(includesPreviewPhoto: true)
    XCTAssertEqual(content.contentURL, .content, .hasContentURL)
    XCTAssertEqual(content.peopleIDs, .peopleIDs, .hasPeopleIDs)
    XCTAssertEqual(content.placeID, .placeID, .hasPlaceID)
    XCTAssertEqual(content.ref, .ref, .hasRef)
    XCTAssertEqual(content.video, .withPreviewPhoto, .hasVideo)
  }

  func testValidationWithValidContent() throws {
    XCTAssertNoThrow(try content.validate(options: []), .validationValidatesVideo)
    XCTAssertIdentical(validator.validateRequiredValueValue as? ShareVideo, content.video, .validationValidatesVideo)
    XCTAssertEqual(validator.validateRequiredValueName, "video", .validationValidatesVideo)
  }

  func testValidationWithDefaultVideo() {
    validator.validateRequiredValueShouldThrow = true
    content = ShareVideoContent()

    XCTAssertThrowsError(try content.validate(options: []), .validationValidatesVideo) { _ in
      XCTAssertIdentical(validator.validateRequiredValueValue as? ShareVideo, content.video, .validationValidatesVideo)
      XCTAssertEqual(validator.validateRequiredValueName, "video", .validationValidatesVideo)
    }
  }

  func testValidationWithInvalidVideoURL() {
    content = ShareVideoContent()
    content.video = ShareVideo()
    content.video.videoURL = .invalid

    XCTAssertThrowsError(try content.validate(options: []), .validationValidatesVideo) { error in
      XCTAssertIdentical(error as AnyObject, testError, .validationValidatesVideo)
      XCTAssertIdentical(validator.validateRequiredValueValue as? ShareVideo, content.video, .validationValidatesVideo)
      XCTAssertEqual(validator.validateRequiredValueName, "video", .validationValidatesVideo)
    }
  }

  func testValidationWithNonVideoURL() {
    content = ShareVideoContent()
    content.video = ShareVideo()
    content.video.videoURL = .photo

    XCTAssertThrowsError(try content.validate(options: []), .validationValidatesVideo) { error in
      XCTAssertIdentical(error as AnyObject, testError, .validationValidatesVideo)
      XCTAssertIdentical(validator.validateRequiredValueValue as? ShareVideo, content.video, .validationValidatesVideo)
      XCTAssertEqual(validator.validateRequiredValueName, "video", .validationValidatesVideo)
    }
  }

  func testValidationWithNetworkVideoURL() {
    content.video = ShareVideo(videoURL: .videoAsset)
    XCTAssertNoThrow(try content.validate(options: []), .validationValidatesVideo)
    XCTAssertIdentical(validator.validateRequiredValueValue as? ShareVideo, content.video, .validationValidatesVideo)
    XCTAssertEqual(validator.validateRequiredValueName, "video", .validationValidatesVideo)
  }

  func testValidationWithValidFileVideoURLWhenBridgeOptionIsDefault() throws {
    content.video = ShareVideo(videoURL: .localVideo)

    XCTAssertThrowsError(try content.validate(options: []), .validationValidatesVideo) { error in
      XCTAssertIdentical(error as AnyObject, testError, .validationValidatesVideo)
      XCTAssertIdentical(validator.validateRequiredValueValue as? ShareVideo, content.video, .validationValidatesVideo)
      XCTAssertEqual(validator.validateRequiredValueName, "video", .validationValidatesVideo)
    }
  }

  func testValidationWithValidFileVideoURLWhenBridgeOptionIsVideoData() throws {
    content.video = ShareVideo(videoURL: .localVideo)

    XCTAssertNoThrow(try content.validate(options: [.videoData]), .validationValidatesVideo)
    XCTAssertIdentical(validator.validateRequiredValueValue as? ShareVideo, content.video, .validationValidatesVideo)
    XCTAssertEqual(validator.validateRequiredValueName, "video", .validationValidatesVideo)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let usesShareUtilityAsShareValidatorByDefault = """
    The default share validator dependency should be the _ShareUtility type
    """
  static let usesCustomShareValidator = "The share validator dependency should be configurable"

  static let hasContentURL = "A share video content has a URL"
  static let hasPeopleIDs = "A share video content has people IDs"
  static let hasPlaceID = "A share video content has a place ID"
  static let hasRef = "A share video content has a ref"
  static let hasVideo = "A share video content has a video"

  static let validationValidatesVideo = """
    Validating a share video content should validate its video using its validator
    """
}

// MARK: - Test values

fileprivate extension URL {
  // swiftlint:disable force_unwrapping
  static let invalid = URL(string: "/")!
  static let content = URL(string: "https://developers.facebook.com/")!
  static let videoAsset = URL(string: "assets-library://asset/asset.mp4?id=86C6970B-1266-42D0-91E8-4E68127D3864&ext=mp4")!
  static let localVideo = Bundle.main.resourceURL!.appendingPathComponent("video.mp4")
  static let photo = URL(string: "https://fbstatic-a.akamaihd.net/rsrc.php/v2/yC/r/YRwxe7CPWSs.png")!
  // swiftlint:enable force_unwrapping
}

fileprivate extension Hashtag {
  static let sample = Hashtag("#sample")
}

fileprivate extension String {
  static let placeID = "141887372509674"
  static let ref = "sample-ref"
}

fileprivate extension Array where Element == String {
  static let peopleIDs = ["person1", "person2"]
}

fileprivate extension ShareVideo {
  static let withPreviewPhoto = ShareVideo(videoURL: .videoAsset, previewPhoto: .withImageURL)
  static let withoutPreviewPhoto = ShareVideo(videoURL: .videoAsset)
}

fileprivate extension SharePhoto {
  static let withImageURL = SharePhoto(imageURL: .photo, isUserGenerated: true)
}

fileprivate extension ShareVideoContent {
  static func sample(includesPreviewPhoto: Bool = false) -> ShareVideoContent {
    let content = ShareVideoContent()
    content.contentURL = .content
    content.hashtag = .sample
    content.peopleIDs = .peopleIDs
    content.placeID = .placeID
    content.ref = .ref
    content.video = includesPreviewPhoto ? .withPreviewPhoto : .withoutPreviewPhoto
    return content
  }
}

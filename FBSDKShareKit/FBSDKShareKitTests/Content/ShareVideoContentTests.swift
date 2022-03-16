/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKShareKit

import FBSDKCoreKit
import UIKit
import XCTest

final class ShareVideoContentTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var content: ShareVideoContent!
  var validator: TestShareUtility.Type!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    validator = TestShareUtility.self
    validator.reset()
    ShareVideoContent.setDependencies(.init(validator: TestShareUtility.self))

    content = ShareModelTestUtility.videoContentWithoutPreviewPhoto
  }

  override func tearDown() {
    ShareVideoContent.resetDependencies()
    validator.reset()
    validator = nil
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
    let content = ShareModelTestUtility.videoContentWithPreviewPhoto
    XCTAssertEqual(content.contentURL, ShareModelTestUtility.contentURL)
    XCTAssertEqual(content.peopleIDs, ShareModelTestUtility.peopleIDs)
    XCTAssertEqual(content.placeID, ShareModelTestUtility.placeID)
    XCTAssertEqual(content.ref, ShareModelTestUtility.ref)
    XCTAssertEqual(content.video, ShareModelTestUtility.videoWithPreviewPhoto)
    XCTAssertEqual(content.video.previewPhoto, ShareModelTestUtility.videoWithPreviewPhoto.previewPhoto)
  }

  func testValidationWithValidContent() throws {
    XCTAssertNoThrow(try content.validate(options: []), .validationValidatesVideo)
    XCTAssertIdentical(validator.validateRequiredValueValue as? ShareVideo, content.video, .validationValidatesVideo)
    XCTAssertEqual(validator.validateRequiredValueName, "video", .validationValidatesVideo)
  }

  func testValidationWithDefaultVideo() {
    validator.validateRequiredValueShouldThrow = true
    content = ShareVideoContent()

    XCTAssertThrowsError(try content.validate(options: []), .validationValidatesVideo)
    XCTAssertIdentical(validator.validateRequiredValueValue as? ShareVideo, content.video, .validationValidatesVideo)
    XCTAssertEqual(validator.validateRequiredValueName, "video", .validationValidatesVideo)
  }

  func testValidationWithInvalidVideoURL() {
    content = ShareVideoContent()
    content.video = ShareVideo()
    // swiftlint:disable:next force_unwrapping
    content.video.videoURL = URL(string: "/")!

    XCTAssertThrowsError(try content.validate(options: []), .validationValidatesVideo) { error in
      let nsError = error as NSError
      XCTAssertNotNil(
        nsError,
        "Attempting to validate video share content with an empty url should return a video url specific error"
      )
      XCTAssertEqual(nsError.code, CoreError.errorInvalidArgument.rawValue)
      XCTAssertEqual(nsError.userInfo[ErrorArgumentNameKey] as? String, "videoURL")
    }
    XCTAssertIdentical(validator.validateRequiredValueValue as? ShareVideo, content.video, .validationValidatesVideo)
    XCTAssertEqual(validator.validateRequiredValueName, "video", .validationValidatesVideo)
  }

  func testValidationWithNonVideoURL() {
    content = ShareVideoContent()
    content.video = ShareVideo()
    content.video.videoURL = ShareModelTestUtility.photoImageURL
    XCTAssertNotNil(content)

    XCTAssertThrowsError(
      try content.validate(options: []),
      "Should throw an error"
    ) { error in
      let nsError = error as NSError
      XCTAssertNotNil(
        nsError,
        "Attempting to validate video share content with a non-video url should return a video url specific error"
      )
      XCTAssertEqual(nsError.code, CoreError.errorInvalidArgument.rawValue)
      XCTAssertEqual(nsError.userInfo[ErrorArgumentNameKey] as? String, "videoURL")
    }
  }

  func testValidationWithNetworkVideoURL() {
    let video = ShareVideo(videoURL: ShareModelTestUtility.videoURL)
    content.video = video
    XCTAssertNoThrow(try content.validate(options: []))
  }

  func testValidationWithValidFileVideoURLWhenBridgeOptionIsDefault() throws {
    let videoURL = try XCTUnwrap(Bundle.main.resourceURL?.appendingPathComponent("video.mp4"))
    content.video = ShareVideo(videoURL: videoURL)

    XCTAssertThrowsError(
      try content.validate(options: []),
      "Should throw an error"
    ) { error in
      let nsError = error as NSError
      XCTAssertNotNil(
        nsError,
        "Attempting to validate video share content with a valid file url should return a video url specific error when there is no specified bridge option to handle video data" // swiftlint:disable:this line_length
      )
      XCTAssertEqual(nsError.code, CoreError.errorInvalidArgument.rawValue)
      XCTAssertEqual(nsError.userInfo[ErrorArgumentNameKey] as? String, "videoURL")
    }
  }

  func testValidationWithValidFileVideoURLWhenBridgeOptionIsVideoData() throws {
    let videoURL = try XCTUnwrap(Bundle.main.resourceURL?.appendingPathComponent("video.mp4"))
    content.video = ShareVideo(videoURL: videoURL)

    XCTAssertNoThrow(try content.validate(options: [.videoData]))
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let usesShareUtilityAsShareValidatorByDefault = """
    The default share validator dependency should be the _ShareUtility type
    """
  static let usesCustomShareValidator = "The share validator dependency should be configurable"

  static let validationValidatesVideo = """
    Validating a share video content should validate its video using its validator
    """
}

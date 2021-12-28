/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import UIKit
import XCTest

// swiftlint:disable line_length
class ShareVideoContentTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var content: ShareVideoContent!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    content = ShareModelTestUtility.videoContentWithoutPreviewPhoto
  }

  override func tearDown() {
    content = nil

    super.tearDown()
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

  func testCopy() {
    let content = ShareModelTestUtility.videoContentWithPreviewPhoto
    XCTAssertEqual(content.copy() as? ShareVideoContent, content)
  }

  func testCoding() {
    let data = NSKeyedArchiver.archivedData(withRootObject: content as Any)
    let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
    unarchiver.requiresSecureCoding = true
    let unarchivedObject = unarchiver.decodeObject(
      of: ShareVideoContent.self,
      forKey: NSKeyedArchiveRootObjectKey
    )
    XCTAssertEqual(unarchivedObject, content)
  }

  func testValidationWithValidContent() throws {
    XCTAssertNoThrow(try ShareUtility.validateShare(content, bridgeOptions: []))
  }

  func testValidationWithNilVideo() {
    content = ShareVideoContent()

    XCTAssertThrowsError(
      try ShareUtility.validateShare(content, bridgeOptions: []),
      "Should throw an error"
    ) { error in
      let nsError = error as NSError
      XCTAssertEqual(nsError.code, CoreError.errorInvalidArgument.rawValue)
      XCTAssertEqual(nsError.userInfo[ErrorArgumentNameKey] as? String, "video")
    }
  }

  func testValidationWithNilVideoURL() {
    content = ShareVideoContent()
    content.video = ShareVideo()

    XCTAssertThrowsError(
      try ShareUtility.validateShare(content, bridgeOptions: []),
      "Should throw an error"
    ) { error in
      let nsError = error as NSError
      XCTAssertNotNil(
        nsError,
        "Attempting to validate video share content with a missing url should return a general video error"
      )
      XCTAssertEqual(nsError.code, CoreError.errorInvalidArgument.rawValue)
      XCTAssertEqual(nsError.userInfo[ErrorArgumentNameKey] as? String, "video")
    }
  }

  func testValidationWithInvalidVideoURL() {
    content = ShareVideoContent()
    content.video = ShareVideo()
    // swiftlint:disable:next force_unwrapping
    content.video.videoURL = URL(string: "/")!

    XCTAssertThrowsError(
      try ShareUtility.validateShare(content, bridgeOptions: []),
      "Should throw an error"
    ) { error in
      let nsError = error as NSError
      XCTAssertNotNil(
        nsError,
        "Attempting to validate video share content with an empty url should return a video url specific error"
      )
      XCTAssertEqual(nsError.code, CoreError.errorInvalidArgument.rawValue)
      XCTAssertEqual(nsError.userInfo[ErrorArgumentNameKey] as? String, "videoURL")
    }
  }

  func testValidationWithNonVideoURL() {
    content = ShareVideoContent()
    content.video = ShareVideo()
    content.video.videoURL = ShareModelTestUtility.photoImageURL
    XCTAssertNotNil(content)

    XCTAssertThrowsError(
      try ShareUtility.validateShare(content, bridgeOptions: []),
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
    XCTAssertNoThrow(try ShareUtility.validateShare(content, bridgeOptions: []))
  }

  func testValidationWithValidFileVideoURLWhenBridgeOptionIsDefault() throws {
    let videoURL = try XCTUnwrap(Bundle.main.resourceURL?.appendingPathComponent("video.mp4"))
    content.video = ShareVideo(videoURL: videoURL)

    XCTAssertThrowsError(
      try ShareUtility.validateShare(content, bridgeOptions: []),
      "Should throw an error"
    ) { error in
      let nsError = error as NSError
      XCTAssertNotNil(
        nsError,
        "Attempting to validate video share content with a valid file url should return a video url specific error when there is no specified bridge option to handle video data"
      )
      XCTAssertEqual(nsError.code, CoreError.errorInvalidArgument.rawValue)
      XCTAssertEqual(nsError.userInfo[ErrorArgumentNameKey] as? String, "videoURL")
    }
  }

  func testValidationWithValidFileVideoURLWhenBridgeOptionIsVideoData() throws {
    let videoURL = try XCTUnwrap(Bundle.main.resourceURL?.appendingPathComponent("video.mp4"))
    content.video = ShareVideo(videoURL: videoURL)

    XCTAssertNoThrow(try ShareUtility.validateShare(content, bridgeOptions: [.videoData]))
  }
}

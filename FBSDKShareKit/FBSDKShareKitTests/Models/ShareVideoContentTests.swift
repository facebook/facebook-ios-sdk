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

final class ShareVideoContentTests: XCTestCase {

  var content: ShareVideoContent! // swiftlint:disable:this implicitly_unwrapped_optional

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

  func testCoding() throws {
    let data = NSKeyedArchiver.archivedData(withRootObject: content as Any)
    let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
    unarchiver.requiresSecureCoding = true
    let unarchivedObject = try XCTUnwrap(
      unarchiver.decodeObject(of: ShareVideoContent.self, forKey: NSKeyedArchiveRootObjectKey)
    )

    XCTAssertEqual(unarchivedObject.contentURL, content.contentURL)
    XCTAssertEqual(unarchivedObject.hashtag, content.hashtag)
    XCTAssertEqual(unarchivedObject.peopleIDs, content.peopleIDs)
    XCTAssertEqual(unarchivedObject.placeID, content.placeID)
    XCTAssertEqual(unarchivedObject.ref, content.ref)
    XCTAssertEqual(unarchivedObject.pageID, content.pageID)
    XCTAssertEqual(unarchivedObject.video.data, content.video.data)
    XCTAssertEqual(unarchivedObject.video.videoAsset, content.video.videoAsset)
    XCTAssertEqual(unarchivedObject.video.videoURL, content.video.videoURL)
    XCTAssertEqual(unarchivedObject.video.previewPhoto, content.video.previewPhoto)
  }

  func testValidationWithValidContent() throws {
    XCTAssertNoThrow(try _ShareUtility.validateShare(content, bridgeOptions: []))
  }

  func testValidationWithNilVideo() {
    content = ShareVideoContent()

    XCTAssertThrowsError(
      try _ShareUtility.validateShare(content, bridgeOptions: []),
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
      try _ShareUtility.validateShare(content, bridgeOptions: []),
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
      try _ShareUtility.validateShare(content, bridgeOptions: []),
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
      try _ShareUtility.validateShare(content, bridgeOptions: []),
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
    XCTAssertNoThrow(try _ShareUtility.validateShare(content, bridgeOptions: []))
  }

  func testValidationWithValidFileVideoURLWhenBridgeOptionIsDefault() throws {
    let videoURL = try XCTUnwrap(Bundle.main.resourceURL?.appendingPathComponent("video.mp4"))
    content.video = ShareVideo(videoURL: videoURL)

    XCTAssertThrowsError(
      try _ShareUtility.validateShare(content, bridgeOptions: []),
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

    XCTAssertNoThrow(try _ShareUtility.validateShare(content, bridgeOptions: [.videoData]))
  }
}

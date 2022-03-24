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
import TestTools
import UIKit
import XCTest

final class ShareVideoContentTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var content: ShareVideoContent!
  var validator: TestShareUtility.Type!
  var mediaLibrarySearcher: TestMediaLibrarySearcher!
  var errorFactory: TestErrorFactory!
  var testError: TestSDKError!
  // swiftlint:enable implicitly_unwrapped_optional

  let originalParameters = ["original": "value"]

  override func setUp() {
    super.setUp()

    validator = TestShareUtility.self
    validator.reset()
    mediaLibrarySearcher = TestMediaLibrarySearcher()
    ShareVideoContent.setDependencies(
      .init(
        validator: TestShareUtility.self,
        mediaLibrarySearcher: mediaLibrarySearcher
      )
    )

    errorFactory = TestErrorFactory()
    testError = TestSDKError(type: .unknown)
    errorFactory.stubbedError = testError
    ShareVideo.setDependencies(.init(errorFactory: errorFactory))
  }

  override func tearDown() {
    ShareVideo.resetDependencies()
    ShareVideoContent.resetDependencies()
    validator.reset()
    validator = nil
    mediaLibrarySearcher = nil
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
    XCTAssertIdentical(
      dependencies.mediaLibrarySearcher as AnyObject,
      PHImageManager.default(),
      .usesPHImageManagerAsMediaLibrarySearcherByDefault
    )
  }

  func testCustomDependencies() throws {
    let dependencies = try ShareVideoContent.getDependencies()
    XCTAssertTrue(dependencies.validator is TestShareUtility.Type, .usesCustomShareValidator)
    XCTAssertIdentical(
      dependencies.mediaLibrarySearcher as AnyObject,
      mediaLibrarySearcher,
      .usesCustomMediaLibrarySearcher
    )
  }

  func testProperties() {
    content = .allProperties

    XCTAssertIdentical(content.video as AnyObject, ShareVideo.plain, .hasVideo)
    XCTAssertEqual(content.contentURL, .content, .hasContentURL)
    XCTAssertIdentical(content.hashtag as AnyObject, Hashtag.sample, .hasHashtag)
    XCTAssertEqual(content.peopleIDs, .peopleIDs, .hasPeopleIDs)
    XCTAssertEqual(content.placeID, .placeID, .hasPlaceID)
    XCTAssertEqual(content.ref, .ref, .hasRef)
    XCTAssertEqual(content.pageID, .pageID, .hasPageID)
    XCTAssertNotNil(content.shareUUID, .hasShareUUID)
  }

  // MARK: - Validation

  func testValidationWithInvalidContent() throws {
    content = ShareVideoContent()

    XCTAssertThrowsError(try content.validate(options: []), .validationValidatesVideo) { _ in
      XCTAssertIdentical(validator.validateRequiredValueValue as? ShareVideo, content.video, .validationValidatesVideo)
      XCTAssertEqual(validator.validateRequiredValueName, "video", .validationValidatesVideo)
    }
  }

  func testValidationWithValidContent() throws {
    content = .valid(.withAssetURLSource)

    XCTAssertNoThrow(try content.validate(options: []), .validationValidatesVideo)
    XCTAssertIdentical(validator.validateRequiredValueValue as? ShareVideo, content.video, .validationValidatesVideo)
    XCTAssertEqual(validator.validateRequiredValueName, "video", .validationValidatesVideo)
  }

  // MARK: - Bridge Parameters

  func testInvalidVideoBridgeParameters() throws {
    content = ShareVideoContent()
    let parameters = content.addParameters(originalParameters, options: [])

    try validateOriginalParameters(in: parameters)
    try validateEmptyVideoParameters(in: parameters, .invalidVideoParameters)
  }

  // MARK: Asset Source

  func testAssetSourceBridgeParametersWithAssetOption() throws {
    content = .valid(.withAssetSource)
    let parameters = content.addParameters(originalParameters, options: .videoAsset)

    try validateOriginalParameters(in: parameters)
    let videoParameters = try getVideoParameters(from: parameters, message: .assetIdentifierParameter)
    let identifier = try XCTUnwrap(videoParameters["assetIdentifier"] as? String, .assetIdentifierParameter)
    XCTAssertEqual(identifier, PHAsset.testAsset.localIdentifier, .assetIdentifierParameter)
  }

  func testAssetSourceBridgeParametersWithoutAssetOption() throws {
    content = .valid(.withAssetSource)
    mediaLibrarySearcher.stubbedGetVideoURL = .asset
    let parameters = content.addParameters(originalParameters, options: [])

    try validateOriginalParameters(in: parameters)
    XCTAssertIdentical(mediaLibrarySearcher.getVideoURLAsset, ShareVideo.withAssetSource.videoAsset, .assetURLParameter)
    let videoParameters = try getVideoParameters(from: parameters, message: .assetURLParameter)
    let url = try XCTUnwrap(videoParameters["assetURL"] as? URL, .assetURLParameter)
    XCTAssertEqual(url, .asset, .assetURLParameter)
  }

  // MARK: Data Source

  func testDataSourceBridgeParametersWithoutDataOption() throws {
    content = .valid(.withDataSource)
    let parameters = content.addParameters(originalParameters, options: [])

    try validateOriginalParameters(in: parameters)
    try validateEmptyVideoParameters(in: parameters, .dataVideoParametersWithoutDataOption)
  }

  func testDataSourceBridgeParametersWithDataOption() throws {
    content = .valid(.withDataSource)
    let parameters = content.addParameters(originalParameters, options: [.videoData])

    try validateOriginalParameters(in: parameters)
    let videoParameters = try getVideoParameters(from: parameters, message: .dataVideoParametersWithDataOption)
    let data = try XCTUnwrap(videoParameters["data"] as? Data, .dataVideoParametersWithDataOption)
    XCTAssertEqual(data, .video, .dataVideoParametersWithDataOption)
  }

  // MARK: URL Source

  func testRemoteURLSourceBridgeParameters() throws {
    content = .valid(.withRemoteURLSource)
    let parameters = content.addParameters(originalParameters, options: [])

    try validateOriginalParameters(in: parameters)
    try validateEmptyVideoParameters(in: parameters, .remoteURLVideoParameters)
  }

  func testURLSourceBridgeParametersWithAssetURL() throws {
    content = .valid(.withAssetURLSource)
    let parameters = content.addParameters(originalParameters, options: [])

    try validateOriginalParameters(in: parameters)
    let videoParameters = try getVideoParameters(from: parameters, message: .urlVideoWithAssetURLParameters)
    let url = try XCTUnwrap(videoParameters["assetURL"] as? URL, .urlVideoWithAssetURLParameters)
    XCTAssertEqual(url, .asset, .urlVideoWithAssetURLParameters)
  }

  func testURLSourceBridgeParametersWithFileURLWithoutDataOption() throws {
    content = .valid(.withFileURLSource)
    let parameters = content.addParameters(originalParameters, options: [])

    try validateOriginalParameters(in: parameters)
    try validateEmptyVideoParameters(in: parameters, .fileURLVideoParametersWithoutDataOption)
  }

  func testVideoURLBridgeParametersWithFileURLWithDataOption() throws {
    content = .valid(.withFileURLSource)
    let parameters = content.addParameters(originalParameters, options: [.videoData])

    try validateOriginalParameters(in: parameters)
    let videoParameters = try getVideoParameters(from: parameters, message: .fileURLVideoParametersWithDataOption)
    let data = try XCTUnwrap(videoParameters["data"] as? Data, .fileURLVideoParametersWithDataOption)
    XCTAssertEqual(data, .video, .fileURLVideoParametersWithDataOption)
  }

  func testMissingPreviewPhotoBridgeParameters() throws {
    content = .withoutPreviewPhoto
    let parameters = content.addParameters(originalParameters, options: [])

    let videoParameters = try getVideoParameters(from: parameters, message: .missingPreviewPhotoParameter)
    XCTAssertNil(videoParameters["previewPhoto"], .missingPreviewPhotoParameter)
  }

  func testPreviewPhotoBridgeParameters() throws {
    content = .withPreviewPhoto
    let parameters = content.addParameters(originalParameters, options: [])

    let videoParameters = try getVideoParameters(from: parameters, message: .previewPhotoParameter)
    let photo = try XCTUnwrap(videoParameters["previewPhoto"] as? SharePhoto, .previewPhotoParameter)
    XCTAssertIdentical(photo, content.video.previewPhoto, .previewPhotoParameter)
  }

  // MARK: - Helpers

  private func validateOriginalParameters(
    in parameters: [String: Any],
    file: StaticString = #file,
    line: UInt = #line
  ) throws {
    let value = try XCTUnwrap(parameters["original"] as? String, .maintainsOriginalParameters, file: file, line: line)
    XCTAssertEqual(value, "value", .maintainsOriginalParameters, file: file, line: line)
  }

  private func getVideoParameters(
    from parameters: [String: Any],
    message: String,
    file: StaticString = #file,
    line: UInt = #line
  ) throws -> [String: Any] {
    try XCTUnwrap(parameters["video"] as? [String: Any], message, file: file, line: line)
  }

  private func validateEmptyVideoParameters(
    in parameters: [String: Any],
    _ message: String,
    file: StaticString = #file,
    line: UInt = #line
  ) throws {
    let videoParameters = try XCTUnwrap(parameters["video"] as? [String: Any], message, file: file, line: line)
    XCTAssertTrue(videoParameters.isEmpty, message, file: file, line: line)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let usesShareUtilityAsShareValidatorByDefault = """
    The default share validator dependency should be the _ShareUtility type
    """
  static let usesPHImageManagerAsMediaLibrarySearcherByDefault = """
    The default media library searching dependency should be the default PHImageManager
    """
  static let usesCustomShareValidator = "The share validator dependency should be configurable"
  static let usesCustomMediaLibrarySearcher = "The media library searching dependency should be configurable"

  static let hasVideo = "A share video content has a video"
  static let hasContentURL = "A share video content can have a content URL"
  static let hasHashtag = "A share video content can have a hashtag"
  static let hasPeopleIDs = "A share video content has people IDs"
  static let hasPlaceID = "A share video content can have a place ID"
  static let hasRef = "A share video content can have a ref"
  static let hasPageID = "A share video content can have a page ID"
  static let hasShareUUID = "A share video content has a share UUID"

  static let validationValidatesVideo = """
    Validating a share video content should validate its video using its validator
    """

  static let maintainsOriginalParameters = "A share video content should maintain the original parameters"
  static let invalidVideoParameters = "An invalid video should not provide any parameters"
  static let assetIdentifierParameter = """
    A video with an asset source should provide the asset's identifier when using the video asset option
    """
  static let assetURLParameter = """
    A video with an asset source should provide the asset's URL when not using the video asset option
    """
  static let dataVideoParametersWithoutDataOption = "A video with a data source should not provide any parameters"
  static let dataVideoParametersWithDataOption = "A video with a data source should provide the video's data"
  static let urlVideoWithAssetURLParameters = "A video with an asset source should provide the asset's data"
  static let fileURLVideoParametersWithoutDataOption = """
    A video with a file URL should not provide any parameters without the video data option
    """
  static let fileURLVideoParametersWithDataOption = "A video with a file URL should provide the video's data"
  static let remoteURLVideoParameters = "A video with a remote URL source should not provide any parameters"
  static let missingPreviewPhotoParameter = """
    A video without a preview photo should not include a preview photo parameter
    """
  static let previewPhotoParameter = "A video with a preview photo should include a preview photo parameter"
}

// MARK: - Test values

fileprivate extension URL {
  // swiftlint:disable force_unwrapping
  static let content = URL(string: "https://developers.facebook.com/")!
  static let remote = URL(string: "https://developers.facebook.com/")!
  static let asset = URL(
    string: "assets-library://asset/asset.mp4?id=86C6970B-1266-42D0-91E8-4E68127D3864&ext=mp4"
  )!
  static let local = Bundle(for: ShareVideoContentTests.self)
    .url(forResource: "dog-or-muffin", withExtension: "jpeg")!
  static let remotePhoto = URL(string: "https://fbstatic-a.akamaihd.net/rsrc.php/v2/yC/r/YRwxe7CPWSs.png")!
  // swiftlint:enable force_unwrapping
}

fileprivate extension Hashtag {
  static let sample = Hashtag("#sample")
}

fileprivate extension String {
  static let placeID = "141887372509674"
  static let ref = "sample-ref"
  static let pageID = "12345"
}

fileprivate extension Array where Element == String {
  static let peopleIDs = ["person1", "person2"]
}

fileprivate extension Data {
  static let video = try! Data(contentsOf: .local, options: .mappedIfSafe) // swiftlint:disable:this force_try
}

fileprivate extension ShareVideo {
  static let plain = ShareVideo()
  static let withAssetSource = ShareVideo(videoAsset: .testAsset)
  static let withDataSource = ShareVideo(data: .video)
  static let withRemoteURLSource = ShareVideo(videoURL: .remote)
  static let withAssetURLSource = ShareVideo(videoURL: .asset)
  static let withFileURLSource = ShareVideo(videoURL: .local)
}

fileprivate extension PHAsset {
  static let testAsset: TestPHAsset = {
    let asset = TestPHAsset()
    asset.stubbedLocalIdentifier = "identifier"
    return asset
  }()
}

fileprivate extension SharePhoto {
  static let sample = SharePhoto(imageURL: .remotePhoto, isUserGenerated: true)
}

fileprivate extension ShareVideoContent {
  static let allProperties: ShareVideoContent = {
    let content = ShareVideoContent()
    content.video = .plain
    content.contentURL = .content
    content.hashtag = .sample
    content.peopleIDs = .peopleIDs
    content.placeID = .placeID
    content.ref = .ref
    content.pageID = .pageID
    return content
  }()

  static func valid(_ video: ShareVideo) -> ShareVideoContent {
    let content = ShareVideoContent()
    content.video = video
    return content
  }

  static let withoutPreviewPhoto = ShareVideoContent()

  static let withPreviewPhoto: ShareVideoContent = {
    let video = ShareVideo()
    video.previewPhoto = .sample
    let content = ShareVideoContent()
    content.video = video
    return content
  }()
}

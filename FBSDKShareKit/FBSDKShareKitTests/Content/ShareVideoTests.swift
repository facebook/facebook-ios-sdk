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

final class ShareVideoTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var video: ShareVideo!
  var errorFactory: TestErrorFactory!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    errorFactory = TestErrorFactory()
    ShareVideo.setDependencies(.init(errorFactory: errorFactory))
  }

  override func tearDown() {
    errorFactory = nil
    ShareVideo.resetDependencies()
    video = nil

    super.tearDown()
  }

  func testDefaultDependencies() throws {
    ShareVideo.resetDependencies()

    let dependencies = try ShareVideo.getDependencies()
    XCTAssertTrue(dependencies.errorFactory is ErrorFactory, .usesConcreteErrorFactoryByDefault)
  }

  func testCustomDependencies() throws {
    let dependencies = try ShareVideo.getDependencies()
    XCTAssertIdentical(dependencies.errorFactory, errorFactory, .usesCustomErrorFactory)
  }

  func testCreatingWithData() {
    video = ShareVideo(data: Data())
    XCTAssertNotNil(video.data, .hasOnlyDataSource)
    XCTAssertNil(video.videoAsset, .hasOnlyDataSource)
    XCTAssertNil(video.videoURL, .hasOnlyDataSource)
  }

  func testCreatingWithAsset() {
    video = ShareVideo(videoAsset: PHAsset())
    XCTAssertNotNil(video.videoAsset, .hasOnlyAssetSource)
    XCTAssertNil(video.data, .hasOnlyAssetSource)
    XCTAssertNil(video.videoURL, .hasOnlyAssetSource)
  }

  func testCreatingWithURL() {
    video = ShareVideo(videoURL: SampleURLs.valid)
    XCTAssertNotNil(video.videoURL, .hasOnlyURLSource)
    XCTAssertNil(video.data, .hasOnlyURLSource)
    XCTAssertNil(video.videoAsset, .hasOnlyURLSource)
  }

  func testChangingSource() {
    video = ShareVideo(data: Data(), previewPhoto: SharePhoto())
    XCTAssertNotNil(video.previewPhoto, .canHavePreviewPhoto)

    video.videoAsset = PHAsset()
    XCTAssertNil(video.data, .otherSourcesClearedWhenChangingSource)
    XCTAssertNil(video.previewPhoto, .previewPhotoClearedWhenChangingSource)

    // Add back preview photo
    video.previewPhoto = SharePhoto()
    XCTAssertNotNil(video.previewPhoto, .canHavePreviewPhoto)

    video.videoURL = SampleURLs.valid
    XCTAssertNil(video.videoAsset, .otherSourcesClearedWhenChangingSource)
    XCTAssertNil(video.previewPhoto, .previewPhotoClearedWhenChangingSource)

    // Add back preview photo
    video.previewPhoto = SharePhoto()
    XCTAssertNotNil(video.previewPhoto, .canHavePreviewPhoto)

    video.data = Data()
    XCTAssertNil(video.videoURL, .otherSourcesClearedWhenChangingSource)
    XCTAssertNil(video.previewPhoto, .previewPhotoClearedWhenChangingSource)
  }

  func testValidatingWithoutSource() {
    video = ShareVideo()

    XCTAssertThrowsError(try video.validate(options: []), .failsValidationWithoutSource) { error in
      guard let sdkError = error as? TestSDKError else {
        return XCTFail(.failsValidationWithoutSource)
      }

      XCTAssertEqual(sdkError.domain, ShareErrorDomain, .failsValidationWithoutSource)
      XCTAssertEqual(sdkError.name, "video", .failsValidationWithoutSource)
      XCTAssertIdentical(sdkError.value as AnyObject, video, .failsValidationWithoutSource)
      XCTAssertEqual(
        sdkError.message,
        "Must have an asset, data, or videoURL value.",
        .failsValidationWithoutSource
      )
      XCTAssertNil(sdkError.underlyingError, .failsValidationWithoutSource)
    }
  }

  func testValidationFailureWithDataSource() {
    let data = Data()
    video = ShareVideo(data: data, previewPhoto: nil)

    XCTAssertThrowsError(
      try video.validate(options: []),
      .failsBadOptionsValidationWithDataSource
    ) { error in
      guard let sdkError = error as? TestSDKError else {
        return XCTFail(.failsBadOptionsValidationWithDataSource)
      }

      XCTAssertEqual(sdkError.domain, ShareErrorDomain, .failsBadOptionsValidationWithDataSource)
      XCTAssertEqual(sdkError.name, "data", .failsBadOptionsValidationWithDataSource)
      XCTAssertEqual(sdkError.value as? Data, data, .failsBadOptionsValidationWithDataSource)
      XCTAssertEqual(
        sdkError.message,
        "Cannot share video data.",
        .failsBadOptionsValidationWithDataSource
      )
      XCTAssertNil(sdkError.underlyingError, .failsBadOptionsValidationWithDataSource)
    }
  }

  func testValidationSuccessWithDataSource() {
    video = ShareVideo(data: Data(), previewPhoto: nil)
    XCTAssertNoThrow(try video.validate(options: .videoData), .passesValidationWithDataSource)
  }

  func testValidationFailureWithAssetSource() {
    let asset = TestPHAsset()
    asset.stubbedMediaType = .audio
    video = ShareVideo(videoAsset: asset, previewPhoto: nil)

    XCTAssertThrowsError(
      try video.validate(options: []),
      .failsBadMediaTypeValidationWithAssetSource
    ) { error in
      guard let sdkError = error as? TestSDKError else {
        return XCTFail(.failsBadMediaTypeValidationWithAssetSource)
      }

      XCTAssertEqual(sdkError.domain, ShareErrorDomain, .failsBadMediaTypeValidationWithAssetSource)
      XCTAssertEqual(sdkError.name, "videoAsset", .failsBadMediaTypeValidationWithAssetSource)
      XCTAssertIdentical(sdkError.value as AnyObject, asset, .failsBadMediaTypeValidationWithAssetSource)
      XCTAssertEqual(
        sdkError.message,
        "Must refer to a video file.",
        .failsBadMediaTypeValidationWithAssetSource
      )
      XCTAssertNil(sdkError.underlyingError, .failsBadMediaTypeValidationWithAssetSource)
    }
  }

  func testValidationSuccessWithAssetSource() {
    let asset = TestPHAsset()
    asset.stubbedMediaType = .video
    video = ShareVideo(videoAsset: asset, previewPhoto: nil)

    XCTAssertNoThrow(try video.validate(options: .videoData), .passesValidationWithAssetSource)
  }

  func testValidationFailureWithRemoteURLSource() {
    let url = URL.remoteVideo
    video = ShareVideo(videoURL: url, previewPhoto: nil)

    XCTAssertThrowsError(
      try video.validate(options: []),
      .failsValidationWithRemoteURLSource
    ) { error in
      guard let sdkError = error as? TestSDKError else {
        return XCTFail(.failsValidationWithRemoteURLSource)
      }

      XCTAssertEqual(sdkError.domain, ShareErrorDomain, .failsValidationWithRemoteURLSource)
      XCTAssertEqual(sdkError.name, "videoURL", .failsValidationWithRemoteURLSource)
      XCTAssertEqual(sdkError.value as? URL, url, .failsValidationWithRemoteURLSource)
      XCTAssertEqual(
        sdkError.message,
        "Must refer to an asset file.",
        .failsValidationWithRemoteURLSource
      )
      XCTAssertNil(sdkError.underlyingError, .failsValidationWithRemoteURLSource)
    }
  }

  func testValidationFailureWithFileURLSource() {
    let url = URL.localVideo
    video = ShareVideo(videoURL: url, previewPhoto: nil)

    XCTAssertThrowsError(
      try video.validate(options: []),
      .failsValidationWithFileURLSource
    ) { error in
      guard let sdkError = error as? TestSDKError else {
        return XCTFail(.failsValidationWithFileURLSource)
      }

      XCTAssertEqual(sdkError.domain, ShareErrorDomain, .failsValidationWithFileURLSource)
      XCTAssertEqual(sdkError.name, "videoURL", .failsValidationWithFileURLSource)
      XCTAssertEqual(sdkError.value as? URL, url, .failsValidationWithFileURLSource)
      XCTAssertEqual(
        sdkError.message,
        "Must refer to an asset file.",
        .failsValidationWithFileURLSource
      )
      XCTAssertNil(sdkError.underlyingError, .failsValidationWithFileURLSource)
    }
  }

  func testValidationSuccessWithAssetLibraryURLSource() throws {
    video = ShareVideo(videoURL: .videoAsset, previewPhoto: nil)
    XCTAssertNoThrow(try video.validate(options: []))
  }

  func testValidationSuccessWithFileURLSource() throws {
    video = ShareVideo(videoURL: .localVideo, previewPhoto: nil)
    XCTAssertNoThrow(try video.validate(options: .videoData))
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let usesConcreteErrorFactoryByDefault = """
    The default error factory dependency should be a concrete ErrorFactory
    """
  static let usesCustomErrorFactory = "The error factory dependency should be configurable"

  static let hasOnlyDataSource = "A video with a data source should only have a data source"
  static let hasOnlyAssetSource = "A video with an asset source should only have an asset source"
  static let hasOnlyURLSource = "A video with a URL source should only have a URL source"
  static let canHavePreviewPhoto = "A video should be able to have a preview photo"
  static let otherSourcesClearedWhenChangingSource = "Changing a video source should clear other sources"
  static let previewPhotoClearedWhenChangingSource = "Changing a video source should clear the preview photo"

  static let failsValidationWithoutSource = "Validating a video without a source should throw an error"
  static let failsBadOptionsValidationWithDataSource = """
    Validating a data source video without using the video data bridge option should throw an error
    """
  static let passesValidationWithDataSource = """
    Validating a data source video with the video data bridge option should not throw an error
    """
  static let failsBadMediaTypeValidationWithAssetSource = """
    Validating an asset source video without the video media type should throw an error
    """
  static let passesValidationWithAssetSource = """
    Validating an asset source video with the video media type should not throw an error
    """
  static let failsValidationWithRemoteURLSource = """
    Validating a URL source video with a remote URL should throw an error
    """
  static let failsValidationWithFileURLSource = """
    Validating a URL source video with a file URL without using the video data bridge option should throw an error
    """
  static let passesValidationWithAssetLibraryURLSource = """
    Validating a URL source video with an asset library URL should not throw an error
    """
  static let passesValidationWithFileURLSource = """
    Validating a URL source video with a file URL and the video data bridge option should not throw an error
    """
}

// MARK: - Test Values

fileprivate extension URL {
  // swiftlint:disable force_unwrapping
  static let videoAsset = URL(string: "assets-library://blah-blah-blah/video.mpg")!
  static let remoteVideo = URL(string: "https://facebook.com/myVideo.mpg")!
  static let localVideo = URL(string: "file:///Users/anyone/myVideo.mpg")!
  // swiftlint:enable force_unwrapping
}

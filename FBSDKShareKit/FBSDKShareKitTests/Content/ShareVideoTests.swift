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

    ShareVideo.unconfigure()
    errorFactory = TestErrorFactory()
    ShareVideo.configure(with: .init(errorFactory: errorFactory))
  }

  override func tearDown() {
    errorFactory = nil
    ShareVideo.unconfigure()
    video = nil

    super.tearDown()
  }

  func testDefaultDependencies() throws {
    ShareVideo.unconfigure()

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
}

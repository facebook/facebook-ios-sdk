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
  private enum Assumptions {
    static let dataSource = "A video with a data source should only have a data source"
    static let assetSource = "A video with an asset source should only have an asset source"
    static let urlSource = "A video with a URL source should only have a URL source"
    static let previewPhoto = "A video should be able to have a preview photo"
    static let clearedSources = "Changing a video source should clear other sources"
    static let clearedPreviewPhoto = "Changing a video source should clear the preview photo"
  }

  var video: ShareVideo! // swiftlint:disable:this implicitly_unwrapped_optional

  override func tearDown() {
    video = nil
    super.tearDown()
  }

  func testCreatingWithData() {
    video = ShareVideo(data: Data())
    XCTAssertNotNil(video.data, Assumptions.dataSource)
    XCTAssertNil(video.videoAsset, Assumptions.dataSource)
    XCTAssertNil(video.videoURL, Assumptions.dataSource)
  }

  func testCreatingWithAsset() {
    video = ShareVideo(videoAsset: PHAsset())
    XCTAssertNotNil(video.videoAsset, Assumptions.assetSource)
    XCTAssertNil(video.data, Assumptions.assetSource)
    XCTAssertNil(video.videoURL, Assumptions.assetSource)
  }

  func testCreatingWithURL() {
    video = ShareVideo(videoURL: SampleURLs.valid)
    XCTAssertNotNil(video.videoURL, Assumptions.urlSource)
    XCTAssertNil(video.data, Assumptions.urlSource)
    XCTAssertNil(video.videoAsset, Assumptions.urlSource)
  }

  func testChangingSource() {
    video = ShareVideo(data: Data(), previewPhoto: SharePhoto())
    XCTAssertNotNil(video.previewPhoto, Assumptions.previewPhoto)

    video.videoAsset = PHAsset()
    XCTAssertNil(video.data, Assumptions.clearedSources)
    XCTAssertNil(video.previewPhoto, Assumptions.clearedPreviewPhoto)

    // Add back preview photo
    video.previewPhoto = SharePhoto()
    XCTAssertNotNil(video.previewPhoto, Assumptions.previewPhoto)

    video.videoURL = SampleURLs.valid
    XCTAssertNil(video.videoAsset, Assumptions.clearedSources)
    XCTAssertNil(video.previewPhoto, Assumptions.clearedPreviewPhoto)

    // Add back preview photo
    video.previewPhoto = SharePhoto()
    XCTAssertNotNil(video.previewPhoto, Assumptions.previewPhoto)

    video.data = Data()
    XCTAssertNil(video.videoURL, Assumptions.clearedSources)
    XCTAssertNil(video.previewPhoto, Assumptions.clearedPreviewPhoto)
  }
}

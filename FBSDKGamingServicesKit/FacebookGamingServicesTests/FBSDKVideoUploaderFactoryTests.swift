/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FacebookGamingServices
import XCTest

class FBSDKVideoUploaderFactoryTests: XCTestCase, VideoUploaderDelegate {

  func testCreatingVideoUploader() {
    let uploader = VideoUploaderFactory().create(
      videoName: name,
      videoSize: 5,
      parameters: ["foo": "bar"],
      delegate: self
    )

    XCTAssertTrue(
      uploader is VideoUploader,
      "Should create the expected concrete video uploader"
    )

    XCTAssertTrue(
      uploader.delegate === self,
      "Should set the expected delegate on the uploader"
    )
  }

  // MARK: - VideoUploaderDelegate conformance

  func videoChunkData(for videoUploader: VideoUploader, startOffset: UInt, endOffset: UInt) -> Data? {
    Data()
  }
  func videoUploader(_ videoUploader: VideoUploader, didCompleteWithResults results: [String: Any]) {}
  func videoUploader(_ videoUploader: VideoUploader, didFailWithError error: Error) {}
}

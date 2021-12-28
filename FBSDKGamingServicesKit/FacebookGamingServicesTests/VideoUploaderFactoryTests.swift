/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FacebookGamingServices
import XCTest

class VideoUploaderFactoryTests: XCTestCase, _VideoUploaderDelegate {

  func testCreatingVideoUploader() {
    let uploader = _VideoUploaderFactory().create(
      videoName: name,
      videoSize: 5,
      parameters: ["foo": "bar"],
      delegate: self
    )

    XCTAssertTrue(
      uploader is _VideoUploader,
      "Should create the expected concrete video uploader"
    )

    XCTAssertTrue(
      uploader.delegate === self,
      "Should set the expected delegate on the uploader"
    )
  }

  // MARK: - VideoUploaderDelegate conformance

  func videoChunkData(for videoUploader: _VideoUploader, startOffset: UInt, endOffset: UInt) -> Data? {
    Data()
  }

  func videoUploader(_ videoUploader: _VideoUploader, didCompleteWithResults results: [String: Any]) {}
  func videoUploader(_ videoUploader: _VideoUploader, didFailWithError error: Error) {}
}

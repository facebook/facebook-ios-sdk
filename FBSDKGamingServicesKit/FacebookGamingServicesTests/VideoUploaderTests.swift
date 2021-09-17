// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import FacebookGamingServices
import FBSDKCoreKit
import TestTools
import XCTest

class VideoUploaderTests: XCTestCase, VideoUploaderDelegate {

  let startOffset = "start_offset"
  let endOffset = "end_offset"

  var uploadDidCompleteSuccessfully = false
  var uploadError: NSError?
  var videoData: Data?

  func videoChunkData(
    for videoUploader: VideoUploader!, // swiftlint:disable:this implicitly_unwrapped_optional
    startOffset: UInt,
    endOffset: UInt
  ) -> Data! {
    videoData = Data("Some Data".utf8)
    return videoData
  }

  func videoUploader(
    _ videoUploader: VideoUploader!, // swiftlint:disable:this implicitly_unwrapped_optional
    didCompleteWithResults results: [String: Any]! // swiftlint:disable:this implicitly_unwrapped_optional
  ) {
    uploadDidCompleteSuccessfully = true
  }

  func videoUploader(
    _ videoUploader: VideoUploader!, // swiftlint:disable:this implicitly_unwrapped_optional
    didFailWithError error: Error! // swiftlint:disable:this implicitly_unwrapped_optional
  ) {
    uploadError = error as NSError
  }

  let graphRequestFactory = TestGraphRequestFactory()
  lazy var videoUploader = VideoUploader(
    videoName: "Greatest Video",
    videoSize: 1,
    parameters: ["a": 1],
    delegate: self,
    graphRequestFactory: graphRequestFactory
  )

  override func setUp() {
    super.setUp()

    videoUploader.uploadSessionID = 1
  }

  func testCompleteParameterTypes() {
    XCTAssertNotNil(
      videoUploader.delegate,
      "VideoUploader should be able to be initialized with a delegate"
    )
    XCTAssertEqual(
      videoUploader.parameters as? [String: Int],
      ["a": 1],
      "VideoUploader should be able to be initialized with parameters"
    )
  }

  func testDefaultGraphNode() {
    XCTAssertEqual(
      videoUploader.graphNode,
      "me",
      "VideoUploader should have a default graph path upon initialization"
    )
  }

  func testGraphRequestPostFinishRequest() {
    videoUploader.start()
    videoUploader._postFinishRequest()
    XCTAssertEqual(
      graphRequestFactory.capturedGraphPath,
      "me/videos",
      "start() should call the graphPathWithSuffix and create the graph path parameter"
    )
    XCTAssertNotNil(graphRequestFactory.capturedHttpMethod)
    XCTAssertNil(
      graphRequestFactory.capturedTokenString,
      "Request Provider should not be initialized with a token string"
    )
  }

  func testGraphRequestFromStartWithVideoSizeZero() {
    let graphRequestFactory = TestGraphRequestFactory()
    let videoUploader = VideoUploader(
      videoName: "Greatest Video",
      videoSize: 0,
      parameters: ["a": 1],
      delegate: self,
      graphRequestFactory: graphRequestFactory
    )
    videoUploader.start()
    XCTAssertNotNil(
      uploadError,
      "Video should not upload and invoke the delegate method with an error if video size is 0"
    )
  }

  func testCompletedUploadVideo() throws {
    let offsets = [startOffset: 1, endOffset: 1]
    videoUploader._startTransferRequest(withOffsetDictionary: offsets)
    let completionHandler = try XCTUnwrap(graphRequestFactory.capturedRequests.first?.capturedCompletionHandler)
    completionHandler(nil, ["success": true], nil)
    XCTAssertTrue(
      uploadDidCompleteSuccessfully,
      "Should invoke the delegate method upon completion."
    )
  }

  func testErrorUploadingVideo() throws {
    let offsets = [startOffset: 1, endOffset: 1]
    videoUploader._startTransferRequest(withOffsetDictionary: offsets)
    let completionHandler = try XCTUnwrap(graphRequestFactory.capturedRequests.first?.capturedCompletionHandler)
    completionHandler(nil, ["none": true], nil)
    XCTAssertFalse(
      uploadDidCompleteSuccessfully,
      "Should not complete upload if result object doesn't have FBSDK_GAMING_VIDEO_UPLOAD_SUCCESS as key"
    )
    XCTAssertNotNil(
      uploadError,
      "Should have error if result object doesn't have FBSDK_GAMING_VIDEO_UPLOAD_SUCCESS as key"
    )
  }

  func testTransferRequestFailWithErrorWhenEndOffsetNil() {
    let offsets = [startOffset: 1]
    videoUploader._startTransferRequest(withOffsetDictionary: offsets)
    XCTAssertFalse(
      uploadDidCompleteSuccessfully,
      "Should not consider a transfer successful if there is no end offset for the video"
    )
  }

  func testStartingTransferRequestWithInvalidOffsets() {
    let offsets = [startOffset: 1, endOffset: 0]
    videoUploader._startTransferRequest(withOffsetDictionary: offsets)
    XCTAssertFalse(
      uploadDidCompleteSuccessfully,
      "Should not complete if end is smaller than start"
    )
  }

  func testStartTransferRequestWithNewOffsetDictionaryFailWithError() throws {
    let offsets = [startOffset: 1, endOffset: 0]
    videoUploader.numberFormatter()
    videoUploader._startTransferRequest(withNewOffset: offsets, data: Data("Some Data".utf8))

    let completionHandler = try XCTUnwrap(graphRequestFactory.capturedRequests.first?.capturedCompletionHandler)
    completionHandler(nil, ["none": true], SampleError())

    XCTAssertFalse(
      uploadDidCompleteSuccessfully,
      "Should not complete if error in completion handler"
    )
    XCTAssertNotNil(
      uploadError,
      "Should not complete if error in completion handler"
    )
  }

  func testExtractOffsetsFromResultDictionaryWithSameValues() {
    let results = [startOffset: "1", endOffset: "1"]
    let extractOffsets = videoUploader._extractOffsets(fromResultDictionary: results)
    XCTAssertEqual(
      extractOffsets.count,
      2,
      "Should return dictionary if start and end are in offset parameter"
    )
  }

  func testExtractOffsetsFromResultDictionaryReturningShareResults() {
    let result = [startOffset: "3", endOffset: "7"]
    let extractOffsets = videoUploader._extractOffsets(fromResultDictionary: result)
    XCTAssertEqual(
      extractOffsets.count,
      2,
      "Should return dictionary if end is larger than start"
    )
  }

  func testExtractOffsetsWithFuzzer() {
    for _ in 0...100 {
      let result = [startOffset: Fuzzer.random, endOffset: Fuzzer.random]
      videoUploader._extractOffsets(fromResultDictionary: result)
    }
  }

  func testExtractOffsetsFromResultDictionaryWithNegativeValues() {
    let result = [startOffset: "-3", endOffset: "-2"]
    let extractOffsets = videoUploader._extractOffsets(fromResultDictionary: result)
    XCTAssertEqual(
      extractOffsets.count,
      2,
      "Should return dictionary if end is smaller than start even as negative values"
    )
  }

  func testExtractOffsetsFromResultDictionaryWithNilOffset() {
    let result = [startOffset: "3"]
    let extractOffsets = videoUploader._extractOffsets(fromResultDictionary: result)
    XCTAssertEqual(
      extractOffsets.count,
      0,
      "Should return empty dictionary if end is missing"
    )
  }

  func testExtractOffsetsFromResultDictionaryInvalidValue() {
    let result = [startOffset: "3", endOffset: "2invalid"]
    let extractOffsets = videoUploader._extractOffsets(fromResultDictionary: result)
    XCTAssertEqual(
      extractOffsets.count,
      0,
      "Should return empty dictionary if end is invalid value"
    )
  }

  func testExtractOffsetsFromResultDictionaryWithDescendingOrder() {
    let result = [startOffset: "3", endOffset: "2"]
    let extractOffsets = videoUploader._extractOffsets(fromResultDictionary: result)
    XCTAssertEqual(
      extractOffsets.count,
      0,
      "Should return empty dictionary if end is smaller than start"
    )
  }
}

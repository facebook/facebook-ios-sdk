/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

// swiftlint:disable identifier_name
let FBSDK_GAMING_RESULT_COMPLETION_GESTURE_KEY = "completionGesture"
let FBSDK_GAMING_RESULT_COMPLETION_GESTURE_VALUE_POST = "post"
let FBSDK_GAMING_VIDEO_END_OFFSET = "end_offset"
let FBSDK_GAMING_VIDEO_FILE_CHUNK = "video_file_chunk"
let FBSDK_GAMING_VIDEO_ID = "video_id"
let FBSDK_GAMING_VIDEO_SIZE = "file_size"
let FBSDK_GAMING_VIDEO_START_OFFSET = "start_offset"
let FBSDK_GAMING_VIDEO_UPLOAD_PHASE = "upload_phase"
let FBSDK_GAMING_VIDEO_UPLOAD_PHASE_FINISH = "finish"
let FBSDK_GAMING_VIDEO_UPLOAD_PHASE_START = "start"
let FBSDK_GAMING_VIDEO_UPLOAD_PHASE_TRANSFER = "transfer"
let FBSDK_GAMING_VIDEO_UPLOAD_SESSION_ID = "upload_session_id"
let FBSDK_GAMING_VIDEO_UPLOAD_SUCCESS = "success"
// swiftlint:enable identifier_name

let FBSDKGamingVideoUploadErrorDomain = "com.facebook.sdk.gaming.videoupload"

let FBSDKVideoUploaderDefaultGraphNode = "me"
let FBSDKVideoUploaderEdge = "videos"

@objcMembers
@objc(FBSDKVideoUploader)
public final class _VideoUploader: NSObject, _VideoUploading {

  var uploadSessionID: Int?
  var graphPath = "me/videos"
  let videoName: String
  var videoSize: UInt = 0
  var videoID: Int?
  let graphRequestFactory: GraphRequestFactoryProtocol
  private static let numberFormatter: NumberFormatter = {
    $0.numberStyle = .decimal
    return $0
  }(NumberFormatter())

  /**
   Optional parameters for video uploads.
   See Graph API documentation for the full list of parameters https://developers.facebook.com/docs/graph-api/reference/video
   */
  public var parameters: [String: Any]

  /**
   The graph node to which video should be uploaded
   */
  public var graphNode = FBSDKVideoUploaderDefaultGraphNode

  /**
   Receiver's delegate
   */
  public weak var delegate: _VideoUploaderDelegate?

  /**
   Initialize VideoUploader
   @param videoName The file name of the video to be uploaded
   @param videoSize The size of the video to be uploaded
   @param parameters Optional parameters for video uploads. See Graph API documentation for the full list of parameters https://developers.facebook.com/docs/graph-api/reference/video
   @param delegate Receiver's delegate
   */
  public convenience init(
    videoName: String,
    videoSize: UInt,
    parameters: [String: Any],
    delegate: _VideoUploaderDelegate
  ) {
    self.init(
      videoName: videoName,
      videoSize: videoSize,
      parameters: parameters,
      delegate: delegate,
      graphRequestFactory: GraphRequestFactory()
    )
  }

  init(
    videoName: String,
    videoSize: UInt,
    parameters: [String: Any],
    delegate: _VideoUploaderDelegate,
    graphRequestFactory: GraphRequestFactoryProtocol
  ) {
    self.parameters = parameters
    self.delegate = delegate
    self.videoName = videoName
    self.videoSize = videoSize
    self.graphRequestFactory = graphRequestFactory
  }

  /**
   Start the upload process
   */
  public func start() {
    graphPath = graphPathWithSuffix(FBSDKVideoUploaderEdge)
    postStartRequest()
  }

  private func postStartRequest() {
    let startRequestCompletionHandler: GraphRequestCompletion = { [weak self] _, result, error in
      guard let self = self else { return }

      if let error = error {
        self.delegate?.videoUploader(self, didFailWithError: error)
        return
      }

      guard
        let result = result as? [String: Any],
        let uploadSessionID = self.extractInt(result[FBSDK_GAMING_VIDEO_UPLOAD_SESSION_ID]),
        let videoID = self.extractInt(result[FBSDK_GAMING_VIDEO_ID])
      else {
        let uploadError = self.errorWithMessage("Failed to get valid upload_session_id or video_id.")
        self.delegate?.videoUploader(self, didFailWithError: uploadError)
        return
      }

      guard let offsetDictionary = self.extractOffsets(fromResultDictionary: result) else {
        return
      }

      self.uploadSessionID = uploadSessionID
      self.videoID = videoID
      self.startTransferRequest(withOffsetDictionary: offsetDictionary)
    }

    guard videoSize != 0 else {
      let uploadError = errorWithMessage("Invalid video size: \(videoSize)")
      delegate?.videoUploader(self, didFailWithError: uploadError)
      return
    }

    let parameters = [
      FBSDK_GAMING_VIDEO_UPLOAD_PHASE: FBSDK_GAMING_VIDEO_UPLOAD_PHASE_START,
      FBSDK_GAMING_VIDEO_SIZE: String(format: "%tu", videoSize),
    ]
    graphRequestFactory.createGraphRequest(
      withGraphPath: graphPath,
      parameters: parameters,
      httpMethod: .post
    )
      .start(completion: startRequestCompletionHandler)
  }

  func startTransferRequest(withOffsetDictionary offsetDictionary: [String: Any]) {
    guard
      let startOffsetInt = extractInt(offsetDictionary[FBSDK_GAMING_VIDEO_START_OFFSET]),
      let endOffsetInt = extractInt(offsetDictionary[FBSDK_GAMING_VIDEO_END_OFFSET]),
      let startOffset = UInt(exactly: startOffsetInt),
      let endOffset = UInt(exactly: endOffsetInt)
    else {
      return
    }

    guard startOffset != endOffset else {
      postFinishRequest()
      return
    }

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self = self else { return }

      guard endOffset >= startOffset else { return }

      let chunkSize = endOffset - startOffset

      guard
        let data = self.delegate?.videoChunkData(for: self, startOffset: startOffset, endOffset: endOffset),
        data.count == chunkSize
      else {
        self.failVideoUploadForChunkSizeOffset(startOffset, endOffset: endOffset)
        return
      }

      self.startTransferRequest(withNewOffset: offsetDictionary, data: data)
    }
  }

  func postFinishRequest() {
    var parameters: [String: Any] = [:]
    parameters[FBSDK_GAMING_VIDEO_UPLOAD_PHASE] = FBSDK_GAMING_VIDEO_UPLOAD_PHASE_FINISH
    if uploadSessionID != nil {
      parameters[FBSDK_GAMING_VIDEO_UPLOAD_SESSION_ID] = uploadSessionID
    }
    parameters.merge(self.parameters) { _, new in new }

    let request = graphRequestFactory.createGraphRequest(
      withGraphPath: graphPath,
      parameters: parameters,
      httpMethod: .post
    )
    request.start { [weak self] _, result, error in
      guard let self = self else { return }

      if let error = error {
        self.delegate?.videoUploader(self, didFailWithError: error)
      } else {
        guard
          let result = result as? [String: Any],
          let resultUploadSuccess = result[FBSDK_GAMING_VIDEO_UPLOAD_SUCCESS]
        else {
          let uploadError = self.errorWithMessage("Failed to finish uploading.")
          self.delegate?.videoUploader(self, didFailWithError: uploadError)
          return
        }

        var shareResult: [String: Any] = [
          FBSDK_GAMING_VIDEO_UPLOAD_SUCCESS: resultUploadSuccess,
          FBSDK_GAMING_RESULT_COMPLETION_GESTURE_KEY: FBSDK_GAMING_RESULT_COMPLETION_GESTURE_VALUE_POST,
        ]

        if let videoID = self.videoID {
          shareResult[FBSDK_GAMING_VIDEO_ID] = videoID
        }

        self.delegate?.videoUploader(self, didCompleteWithResults: shareResult)
      }
    }
  }

  func extractOffsets(fromResultDictionary result: Any) -> [String: Any]? {
    guard
      let result = result as? [String: Any],
      let startOffsetString = result[FBSDK_GAMING_VIDEO_START_OFFSET] as? String,
      let endOffsetString = result[FBSDK_GAMING_VIDEO_END_OFFSET] as? String
    else {
      return nil
    }

    guard
      let startNum = Int(startOffsetString),
      let endNum = Int(endOffsetString)
    else {
      let uploadError = errorWithMessage("Fail to get valid start_offset or end_offset.")
      delegate?.videoUploader(self, didFailWithError: uploadError)
      return nil
    }

    guard startNum <= endNum else {
      let uploadError = errorWithMessage("Invalid offset: start_offset is greater than end_offset.")
      delegate?.videoUploader(self, didFailWithError: uploadError)
      return nil
    }

    let shareResults: [String: Any] = [
      FBSDK_GAMING_VIDEO_START_OFFSET: startNum,
      FBSDK_GAMING_VIDEO_END_OFFSET: endNum
    ]

    return shareResults
  }

  func startTransferRequest(withNewOffset offsetDictionary: [String: Any], data: Data) {
    let dataAttachment = GraphRequestDataAttachment(
      data: data,
      filename: videoName,
      contentType: ""
    )

    var parameters: [String: Any] = [
      FBSDK_GAMING_VIDEO_UPLOAD_PHASE: FBSDK_GAMING_VIDEO_UPLOAD_PHASE_TRANSFER,
      FBSDK_GAMING_VIDEO_FILE_CHUNK: dataAttachment,
    ]

    if let startOffset = offsetDictionary[FBSDK_GAMING_VIDEO_START_OFFSET] {
      parameters[FBSDK_GAMING_VIDEO_START_OFFSET] = startOffset
    }

    if let uploadSessionID = uploadSessionID {
      parameters[FBSDK_GAMING_VIDEO_UPLOAD_SESSION_ID] = uploadSessionID
    }

    let request = graphRequestFactory.createGraphRequest(
      withGraphPath: graphPath,
      parameters: parameters,
      httpMethod: .post
    )

    request.start { _, _, innerError in
      if let innerError = innerError {
        self.delegate?.videoUploader(self, didFailWithError: innerError)
        return
      }

      guard let innerOffsetDictionary = self.extractOffsets(fromResultDictionary: offsetDictionary) else {
        return
      }

      self.startTransferRequest(withOffsetDictionary: innerOffsetDictionary)
    }
  }

  private func failVideoUploadForChunkSizeOffset(_ startOffset: UInt, endOffset: UInt) {
    let message = "Fail to get video chunk with start offset: \(startOffset), end offset: \(endOffset)."
    let uploadError = errorWithMessage(message)
    delegate?.videoUploader(self, didFailWithError: uploadError)
  }

  private func graphPathWithSuffix(_ suffix: String) -> String {
    graphNode + "/" + suffix
  }

  private func errorWithMessage(_ message: String) -> Error {
    let errorFactory = ErrorFactory()
    return errorFactory.error(
      domain: FBSDKGamingVideoUploadErrorDomain,
      code: 0,
      userInfo: nil,
      message: message,
      underlyingError: nil
    )
  }

  private func extractInt(_ num: Any?) -> Int? {
    if let int = num as? Int {
      return int
    } else if let string = num as? String {
      return Int(string)
    } else {
      return nil
    }
  }
}

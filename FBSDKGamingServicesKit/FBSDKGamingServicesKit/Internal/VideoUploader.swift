/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

final class VideoUploader: VideoUploading {
  private enum Keys {
    static let videoUploaderDefaultGraphNode = "me"
    static let videoUploaderEdge = "videos"

    static let resultCompletionGesture = "completionGesture"
    static let resultCompletionGestureValuePost = "post"

    static let videoEndOffset = "end_offset"
    static let videoFileChunk = "video_file_chunk"
    static let videoID = "video_id"
    static let videoSize = "file_size"
    static let videoStartOffset = "start_offset"
    static let videoUploadPhase = "upload_phase"
    static let videoUploadPhaseFinish = "finish"
    static let videoUploadPhaseStart = "start"
    static let videoUploadPhaseTransfer = "transfer"
    static let videoUploadSessionID = "upload_session_id"
    static let videoUploadSuccess = "success"
  }

  private let videoName: String
  private let videoSize: UInt
  let parameters: [String: Any]
  private let graphRequestFactory: GraphRequestFactoryProtocol

  private var videoID: Int?
  var uploadSessionID: Int?
  private var graphPath: String {
    "\(graphNode)/\(Keys.videoUploaderEdge)"
  }

  /// The graph node to which video should be uploaded
  var graphNode = Keys.videoUploaderDefaultGraphNode

  /// Receiver's delegate
  weak var delegate: VideoUploaderDelegate?

  /**
   Initialize VideoUploader
   @param videoName The file name of the video to be uploaded
   @param videoSize The size of the video to be uploaded
   @param parameters Optional parameters for video uploads. See Graph API documentation for the full list of parameters https://developers.facebook.com/docs/graph-api/reference/video
   @param delegate Receiver's delegate
   */
  convenience init(
    videoName: String,
    videoSize: UInt,
    parameters: [String: Any],
    delegate: VideoUploaderDelegate
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
    delegate: VideoUploaderDelegate,
    graphRequestFactory: GraphRequestFactoryProtocol
  ) {
    self.parameters = parameters
    self.delegate = delegate
    self.videoName = videoName
    self.videoSize = videoSize
    self.graphRequestFactory = graphRequestFactory
  }

  /// Start the upload process
  func start() {
    guard videoSize != 0 else {
      let uploadError = errorWithMessage("Invalid video size: \(videoSize)")
      delegate?.videoUploader(self, didFailWithError: uploadError)
      return
    }

    let parameters = [
      Keys.videoUploadPhase: Keys.videoUploadPhaseStart,
      Keys.videoSize: String(format: "%tu", videoSize),
    ]
    let request = graphRequestFactory.createGraphRequest(
      withGraphPath: graphPath,
      parameters: parameters,
      httpMethod: .post
    )
    request.start { [weak self] _, result, error in
      guard let self = self else { return }

      if let error = error {
        self.delegate?.videoUploader(self, didFailWithError: error)
        return
      }

      guard
        let result = result as? [String: Any],
        let uploadSessionID = self.extractInt(result[Keys.videoUploadSessionID]),
        let videoID = self.extractInt(result[Keys.videoID])
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
  }

  func startTransferRequest(withOffsetDictionary offsetDictionary: [String: Any]) {
    guard
      let startOffsetInt = extractInt(offsetDictionary[Keys.videoStartOffset]),
      let endOffsetInt = extractInt(offsetDictionary[Keys.videoEndOffset]),
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
    var parameters: [String: Any] = [
      Keys.videoUploadPhase: Keys.videoUploadPhaseFinish,
    ]
    if let uploadSessionID = uploadSessionID {
      parameters[Keys.videoUploadSessionID] = uploadSessionID
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
        return
      }

      guard
        let result = result as? [String: Any],
        let resultUploadSuccess = result[Keys.videoUploadSuccess]
      else {
        let uploadError = self.errorWithMessage("Failed to finish uploading.")
        self.delegate?.videoUploader(self, didFailWithError: uploadError)
        return
      }

      var shareResult: [String: Any] = [
        Keys.videoUploadSuccess: resultUploadSuccess,
        Keys.resultCompletionGesture: Keys.resultCompletionGestureValuePost,
      ]

      if let videoID = self.videoID {
        shareResult[Keys.videoID] = videoID
      }

      self.delegate?.videoUploader(self, didCompleteWithResults: shareResult)
    }
  }

  func extractOffsets(fromResultDictionary result: Any) -> [String: Any]? {
    guard
      let result = result as? [String: Any],
      let startOffsetString = result[Keys.videoStartOffset] as? String,
      let endOffsetString = result[Keys.videoEndOffset] as? String
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
      Keys.videoStartOffset: startNum,
      Keys.videoEndOffset: endNum,
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
      Keys.videoUploadPhase: Keys.videoUploadPhaseTransfer,
      Keys.videoFileChunk: dataAttachment,
    ]

    if let startOffset = offsetDictionary[Keys.videoStartOffset] {
      parameters[Keys.videoStartOffset] = startOffset
    }

    if let uploadSessionID = uploadSessionID {
      parameters[Keys.videoUploadSessionID] = uploadSessionID
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

  private func errorWithMessage(_ message: String) -> Error {
    let errorFactory = ErrorFactory()
    return errorFactory.error(
      domain: "com.facebook.sdk.gaming.videoupload",
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

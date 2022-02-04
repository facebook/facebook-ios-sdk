/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

@objcMembers
@objc(FBSDKGamingVideoUploader)
public final class GamingVideoUploader: NSObject {

  private var totalBytesSent: UInt = 0
  private var totalBytesExpectedToSend: UInt = 0

  var fileHandle: FileHandling?
  let fileHandleFactory: FileHandleCreating
  let videoUploaderFactory: VideoUploaderCreating

  var completionHandler: GamingServiceResultCompletion?
  var progressHandler: GamingServiceProgressHandler?

  // Transitional singleton introduced as a way to change the usage semantics
  // from a type-based interface to an instance-based interface.
  // The goal is to move from:
  // ClassWithoutUnderlyingInstance -> ClassRelyingOnUnderlyingInstance -> Instance
  static let shared = GamingVideoUploader()

  init(
    fileHandleFactory: FileHandleCreating = FileHandleFactory(),
    videoUploaderFactory: VideoUploaderCreating = VideoUploaderFactory()
  ) {
    self.fileHandleFactory = fileHandleFactory
    self.videoUploaderFactory = videoUploaderFactory
  }

  private convenience init(
    fileHandle: FileHandling,
    totalBytesExpectedToSend: UInt,
    completionHandler: GamingServiceResultCompletion?,
    progressHandler: GamingServiceProgressHandler?
  ) {
    self.init()
    self.fileHandle = fileHandle
    self.totalBytesExpectedToSend = totalBytesExpectedToSend
    self.completionHandler = completionHandler
    self.progressHandler = progressHandler
  }

  /**
   Runs an upload to a users Gaming Media Library with the given configuration

   @param configuration model object contain the content that will be uploaded
   @param completion a callback that is fired when the upload completes.
   */
  @objc(uploadVideoWithConfiguration:andResultCompletion:)
  public static func uploadVideo(
    configuration: GamingVideoUploaderConfiguration,
    completion: @escaping GamingServiceResultCompletion
  ) {
    shared.uploadVideo(
      configuration: configuration,
      completion: completion
    )
  }

  func uploadVideo(
    configuration: GamingVideoUploaderConfiguration,
    completion: @escaping GamingServiceResultCompletion
  ) {
    uploadVideo(
      configuration: configuration,
      completion: completion,
      progressHandler: nil
    )
  }

  /**
   Runs an upload to a users Gaming Media Library with the given configuration

   @param configuration model object contain the content that will be uploaded
   @param completion a callback that is fired when the upload completes.
   @param progressHandler an optional callback that is fired multiple times as bytes are transferred to Facebook.
   */
  @objc(uploadVideoWithConfiguration:completion:andProgressHandler:)
  public static func uploadVideo(
    configuration: GamingVideoUploaderConfiguration,
    completion: @escaping GamingServiceResultCompletion,
    progressHandler: GamingServiceProgressHandler?
  ) {
    shared.uploadVideo(
      configuration: configuration,
      completion: completion,
      progressHandler: progressHandler
    )
  }

  func uploadVideo(
    configuration: GamingVideoUploaderConfiguration,
    completion: @escaping GamingServiceResultCompletion,
    progressHandler: GamingServiceProgressHandler?
  ) {
    let errorFactory = ErrorFactory()

    guard AccessToken.current != nil else {
      completion(
        false,
        nil,
        errorFactory.error(
          code: CoreError.errorAccessTokenRequired.rawValue,
          userInfo: nil,
          message: "A valid access token is required to upload Images",
          underlyingError: nil
        )
      )

      return
    }

    guard
      let fileHandle = try? fileHandleFactory.fileHandleForReading(from: configuration.videoURL),
      fileHandle.seekToEndOfFile() != 0
    else {
      completion(
        false,
        nil,
        errorFactory.error(
          code: CoreError.errorInvalidArgument.rawValue,
          userInfo: nil,
          message: "Attempting to upload an empty video file",
          underlyingError: nil
        )
      )

      return
    }

    let fileSize = UInt(fileHandle.seekToEndOfFile())

    let uploader = GamingVideoUploader(
      fileHandle: fileHandle,
      totalBytesExpectedToSend: fileSize,
      completionHandler: completion,
      progressHandler: progressHandler
    )

    InternalUtility.shared.registerTransientObject(uploader)

    let videoUploader = videoUploaderFactory.create(
      videoName: configuration.videoURL.lastPathComponent,
      videoSize: fileSize,
      parameters: [:],
      delegate: uploader
    )

    videoUploader.start()
  }

  private func safelyComplete(
    success: Bool,
    error: Error?,
    result: [String: Any]?
  ) {
    var finalError = error

    if !success,
       error == nil {
      finalError = ErrorFactory().error(
        code: CoreError.errorUnknown.rawValue,
        userInfo: nil,
        message: "Video upload was unsuccessful, but no error was thrown.",
        underlyingError: nil
      )
    }

    completionHandler?(success, result, finalError)

    InternalUtility.shared.unregisterTransientObject(self)
  }

  private func safelyHandleProgress(totalBytesSent: UInt) {
    guard let progressHandler = progressHandler else { return }

    let bytesSent = totalBytesSent - self.totalBytesSent
    self.totalBytesSent = totalBytesSent

    progressHandler(
      Int64(bytesSent),
      Int64(self.totalBytesSent),
      Int64(totalBytesExpectedToSend)
    )
  }
}

// MARK: - VideoUploaderDelegate

extension GamingVideoUploader: VideoUploaderDelegate {

  func videoChunkData(
    for videoUploader: VideoUploader,
    startOffset: UInt,
    endOffset: UInt
  ) -> Data? {
    let chunkSize = endOffset - startOffset
    guard let fileHandle = fileHandle else { return nil }

    fileHandle.seek(toFileOffset: UInt64(startOffset))
    let videoChunkData = fileHandle.readData(ofLength: Int(chunkSize))
    guard videoChunkData.count == chunkSize else {
      return nil
    }

    safelyHandleProgress(totalBytesSent: startOffset)

    return videoChunkData
  }

  func videoUploader(
    _ videoUploader: VideoUploader,
    didCompleteWithResults results: [String: Any]
  ) {
    safelyHandleProgress(totalBytesSent: totalBytesExpectedToSend)

    var serverSuccess = false
    let success = results["success"]

    if let stringSuccess = success as? NSString {
      serverSuccess = stringSuccess.boolValue
    } else if let numberSuccess = success as? NSNumber {
      serverSuccess = numberSuccess.boolValue
    }

    safelyComplete(
      success: serverSuccess,
      error: nil,
      result: ["video_id": results["video_id"] ?? ""]
    )
  }

  func videoUploader(
    _ videoUploader: VideoUploader,
    didFailWithError error: Error
  ) {
    safelyComplete(
      success: false,
      error: error,
      result: nil
    )
  }
}

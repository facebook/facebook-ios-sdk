/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

@objcMembers
@objc(FBSDKGamingVideoUploader)
public final class GamingVideoUploader: NSObject {

  private var totalBytesSent: UInt = 0
  private var totalBytesExpectedToSend: UInt = 0

  var fileHandle: _FileHandling?
  let fileHandleFactory: _FileHandleCreating
  let videoUploaderFactory: _VideoUploaderCreating

  var completionHandler: GamingServiceResultCompletion?
  var progressHandler: GamingServiceProgressHandler?

  // Transitional singleton introduced as a way to change the usage semantics
  // from a type-based interface to an instance-based interface.
  // The goal is to move from:
  // ClassWithoutUnderlyingInstance -> ClassRelyingOnUnderlyingInstance -> Instance
  static let shared = GamingVideoUploader()

  override convenience init() {
    self.init(
      fileHandleFactory: _FileHandleFactory(),
      videoUploaderFactory: _VideoUploaderFactory()
    )
  }

  init(
    fileHandleFactory: _FileHandleCreating,
    videoUploaderFactory: _VideoUploaderCreating
  ) {
    self.fileHandleFactory = fileHandleFactory
    self.videoUploaderFactory = videoUploaderFactory
  }

  static func createWithFileHandle(
    _ fileHandle: _FileHandling,
    totalBytesToSend totalBytes: UInt,
    completionHandler: GamingServiceResultCompletion?,
    progressHandler: GamingServiceProgressHandler?
  ) -> GamingVideoUploader {
    let uploader = GamingVideoUploader()
    uploader.fileHandle = fileHandle
    uploader.totalBytesExpectedToSend = totalBytes
    uploader.completionHandler = completionHandler
    uploader.progressHandler = progressHandler

    return uploader
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
      with: configuration,
      andResultCompletion: completion
    )
  }

  func uploadVideo(
    with configuration: GamingVideoUploaderConfiguration,
    andResultCompletion completion: @escaping GamingServiceResultCompletion
  ) {
    uploadVideo(
      with: configuration,
      completion: completion,
      andProgressHandler: nil
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
      with: configuration,
      completion: completion,
      andProgressHandler: progressHandler
    )
  }

  func uploadVideo(
    with configuration: GamingVideoUploaderConfiguration,
    completion: @escaping GamingServiceResultCompletion,
    andProgressHandler progressHandler: GamingServiceProgressHandler?
  ) {
    let errorFactory = ErrorFactory()

    if AccessToken.current == nil {
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

    let fileSize = fileHandle.seekToEndOfFile()

    let uploader = GamingVideoUploader.createWithFileHandle(
      fileHandle,
      totalBytesToSend: UInt(fileSize),
      completionHandler: completion,
      progressHandler: progressHandler
    )

    InternalUtility.shared.registerTransientObject(uploader)

    let videoUploader = videoUploaderFactory.create(
      videoName: configuration.videoURL.lastPathComponent,
      videoSize: UInt(fileSize),
      parameters: [:],
      delegate: uploader
    )

    videoUploader.start()
  }

  func safeCompleteWithSuccess(
    _ success: Bool,
    error: Error?,
    result: Any?
  ) {
    var finalError = error

    if success == false, error == nil {
      let errorFactory = ErrorFactory()
      finalError = errorFactory.error(
        code: CoreError.errorUnknown.rawValue,
        userInfo: nil,
        message: "Video upload was unsuccessful, but no error was thrown.",
        underlyingError: nil
      )
    }

    completionHandler?(success, result as? [String: Any], finalError)

    InternalUtility.shared.unregisterTransientObject(self)
  }

  func safeProgressWithTotalBytesSent(_ totalBytesSent: UInt) {
    guard let progressHandler = progressHandler else { return }

    let bytesSent = totalBytesSent - self.totalBytesSent
    self.totalBytesSent = totalBytesSent

    progressHandler(Int64(bytesSent), Int64(self.totalBytesSent), Int64(totalBytesExpectedToSend))
  }
}

// MARK: - _VideoUploaderDelegate

extension GamingVideoUploader: _VideoUploaderDelegate {

  public func videoChunkData(
    for videoUploader: _VideoUploader,
    startOffset: UInt,
    endOffset: UInt
  ) -> Data? {
    let chunkSize = endOffset - startOffset
    guard let fileHandle = fileHandle else { return nil }
    fileHandle.seek(toFileOffset: UInt64(startOffset))
    let videoChunkData = fileHandle.readData(ofLength: Int(chunkSize))
    if videoChunkData.count != chunkSize {
      return nil
    }

    safeProgressWithTotalBytesSent(startOffset)

    return videoChunkData
  }

  public func videoUploader(
    _ videoUploader: _VideoUploader,
    didCompleteWithResults results: [String: Any]
  ) {
    safeProgressWithTotalBytesSent(totalBytesExpectedToSend)

    var serverSuccess = false
    let success = results["success"]

    if let stringSuccess = success as? NSString {
      serverSuccess = stringSuccess.boolValue
    } else if let numberSuccess = success as? NSNumber {
      serverSuccess = numberSuccess.boolValue
    }

    safeCompleteWithSuccess(
      serverSuccess,
      error: nil,
      result: ["video_id": results["video_id"] ?? ""]
    )
  }

  public func videoUploader(
    _ videoUploader: _VideoUploader,
    didFailWithError error: Error
  ) {
    safeCompleteWithSuccess(
      false,
      error: error,
      result: nil
    )
  }
}

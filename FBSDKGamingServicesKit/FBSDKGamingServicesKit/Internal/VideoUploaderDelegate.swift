/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/**
 A delegate for `VideoUploader`.
 The delegate passes video chunk to `VideoUploader` object in `Data` format and is notified with the results of the uploader.
 */
protocol VideoUploaderDelegate: AnyObject {
  /**
   Get chunk of the video to be uploaded in 'NSData' format
   @param videoUploader The `FBSDKVideoUploader` object which is performing the upload process
   @param startOffset The start offset of video chunk to be uploaded
   @param endOffset The end offset of video chunk being to be uploaded
   */
  func videoChunkData(for videoUploader: VideoUploader, startOffset: UInt, endOffset: UInt) -> Data?

  /**
   Notify the delegate that upload process success.
   @param videoUploader The `FBSDKVideoUploader` object which is performing the upload process
   @param results The result from successful upload
   */
  func videoUploader(_ videoUploader: VideoUploader, didCompleteWithResults results: [String: Any])

  /**
   Notify the delegate that upload process fails.
   @param videoUploader The `FBSDKVideoUploader` object which is performing the upload process
   @param error The error object from unsuccessful upload
   */
  func videoUploader(_ videoUploader: VideoUploader, didFailWithError error: Error)
}

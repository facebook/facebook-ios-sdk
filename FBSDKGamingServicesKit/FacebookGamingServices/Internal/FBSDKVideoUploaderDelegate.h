/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

NS_ASSUME_NONNULL_BEGIN

@class FBSDKVideoUploader;

/**
 A delegate for `FBSDKVideoUploader`.

 The delegate passes video chunk to `FBSDKVideoUploader` object in `NSData` format and is notified with the results of the uploader.
 */
NS_SWIFT_NAME(VideoUploaderDelegate)
@protocol FBSDKVideoUploaderDelegate <NSObject>

/**
 Get chunk of the video to be uploaded in 'NSData' format
 @param videoUploader The `FBSDKVideoUploader` object which is performing the upload process
 @param startOffset The start offset of video chunk to be uploaded
 @param endOffset The end offset of video chunk being to be uploaded
 */
- (nullable NSData *)videoChunkDataForVideoUploader:(FBSDKVideoUploader *)videoUploader startOffset:(NSUInteger)startOffset endOffset:(NSUInteger)endOffset;

/**
 Notify the delegate that upload process success.
 @param videoUploader The `FBSDKVideoUploader` object which is performing the upload process
 @param results The result from successful upload
 */
- (void)   videoUploader:(FBSDKVideoUploader *)videoUploader
  didCompleteWithResults:(NSDictionary<NSString *, id> *)results;

/**
 Notify the delegate that upload process fails.
 @param videoUploader The `FBSDKVideoUploader` object which is performing the upload process
 @param error The error object from unsuccessful upload
 */
- (void)videoUploader:(FBSDKVideoUploader *)videoUploader didFailWithError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END

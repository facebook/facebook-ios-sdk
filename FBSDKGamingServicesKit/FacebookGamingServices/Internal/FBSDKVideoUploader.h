/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKVideoUploaderDelegate;

/**
  A utility class for uploading through the chunk upload graph API.  Using this class requires an access token in
 `[FBSDKAccessToken currentAccessToken]` that has been granted the "publish_actions" permission.

 see https://developers.facebook.com/docs/graph-api/video-uploads
 */
NS_SWIFT_NAME(VideoUploader)
@interface FBSDKVideoUploader : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
  Initialize videoUploader
 @param videoName The file name of the video to be uploaded
 @param videoSize The size of the video to be uploaded
 @param parameters Optional parameters for video uploads. See Graph API documentation for the full list of parameters https://developers.facebook.com/docs/graph-api/reference/video
 @param delegate Receiver's delegate
 */
- (instancetype)initWithVideoName:(NSString *)videoName videoSize:(NSUInteger)videoSize parameters:(NSDictionary<NSString *, id> *)parameters delegate:(id<FBSDKVideoUploaderDelegate>)delegate;

/**
  Optional parameters for video uploads. See Graph API documentation for the full list of parameters https://developers.facebook.com/docs/graph-api/reference/video
 */
@property (nonatomic, copy) NSDictionary<NSString *, id> *parameters;

/**
  The graph node to which video should be uploaded
 */
@property (nonatomic, copy) NSString *graphNode;

/**
  Receiver's delegate
 */
@property (nonatomic, weak) id<FBSDKVideoUploaderDelegate> delegate;

/**
  Start upload process
 */
// TODO #6229672 add cancel and/or pause
- (void)start;

@end

/**
  A delegate for `FBSDKVideoUploader`.

 The delegate passes video chunk to `FBSDKVideoUploader` object in `NSData` format and is notified with the results of the uploader.
 */
NS_SWIFT_NAME(VideoUploaderDelegate)
@protocol FBSDKVideoUploaderDelegate <NSObject>

/**
  get chunk of the video to be uploaded in 'NSData' format
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

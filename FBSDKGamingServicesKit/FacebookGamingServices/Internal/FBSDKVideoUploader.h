/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKVideoUploaderDelegate.h"
#import "FBSDKVideoUploading.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKVideoUploaderDelegate;

/**
 A utility class for uploading through the chunk upload graph API. Using this class requires an access token in
 `[FBSDKAccessToken currentAccessToken]` that has been granted the "publish_actions" permission.

 See https://developers.facebook.com/docs/graph-api/video-uploads
 */
NS_SWIFT_NAME(VideoUploader)
@interface FBSDKVideoUploader : NSObject <FBSDKVideoUploading>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 Initialize VideoUploader
 @param videoName The file name of the video to be uploaded
 @param videoSize The size of the video to be uploaded
 @param parameters Optional parameters for video uploads. See Graph API documentation for the full list of parameters https://developers.facebook.com/docs/graph-api/reference/video
 @param delegate Receiver's delegate
 */
- (instancetype)initWithVideoName:(NSString *)videoName videoSize:(NSUInteger)videoSize parameters:(NSDictionary<NSString *, id> *)parameters delegate:(id<FBSDKVideoUploaderDelegate>)delegate;

/**
 Optional parameters for video uploads.
 See Graph API documentation for the full list of parameters https://developers.facebook.com/docs/graph-api/reference/video
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
 Start the upload process
 */
- (void)start;

@end

NS_ASSUME_NONNULL_END

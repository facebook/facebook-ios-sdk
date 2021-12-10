/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@import FacebookGamingServices;

@protocol FBSDKFileHandleCreating;
@protocol FBSDKVideoUploaderCreating;

#import "FBSDKVideoUploader.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKGamingVideoUploader (Testing) <FBSDKVideoUploaderDelegate>

@property (class, nonatomic, readonly) FBSDKGamingVideoUploader *shared;
@property (nonatomic) id<FBSDKFileHandleCreating> fileHandleFactory;
@property (nonatomic) id<FBSDKVideoUploaderCreating> videoUploaderFactory;

- (instancetype)initWithFileHandleFactory:(id<FBSDKFileHandleCreating>)fileHandleFactory
                     videoUploaderFactory:(id<FBSDKVideoUploaderCreating>)videoUploaderFactory;

- (void)uploadVideoWithConfiguration:(FBSDKGamingVideoUploaderConfiguration *_Nonnull)configuration
                 andResultCompletion:(FBSDKGamingServiceResultCompletion _Nonnull)completion;

- (void)uploadVideoWithConfiguration:(FBSDKGamingVideoUploaderConfiguration *_Nonnull)configuration
                          completion:(FBSDKGamingServiceResultCompletion _Nonnull)completion
                  andProgressHandler:(FBSDKGamingServiceProgressHandler _Nullable)progressHandler;

@end

NS_ASSUME_NONNULL_END

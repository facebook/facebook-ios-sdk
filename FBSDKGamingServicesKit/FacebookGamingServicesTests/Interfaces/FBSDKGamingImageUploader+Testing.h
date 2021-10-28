/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@import FacebookGamingServices;

@protocol FBSDKGamingServiceControllerCreating;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKGamingImageUploader (Testing)

@property (class, nonnull, nonatomic, readonly) FBSDKGamingImageUploader *shared;
@property (nonnull, nonatomic) id<FBSDKGamingServiceControllerCreating> factory;
@property (nonnull, nonatomic) id<FBSDKGraphRequestConnectionFactory> graphRequestConnectionFactory;

- (instancetype)initWithGamingServiceControllerFactory:(id<FBSDKGamingServiceControllerCreating>)factory
                         graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory;

- (void)uploadImageWithConfiguration:(FBSDKGamingImageUploaderConfiguration *_Nonnull)configuration
                 andResultCompletion:(FBSDKGamingServiceResultCompletion _Nonnull)completion;

- (void)uploadImageWithConfiguration:(FBSDKGamingImageUploaderConfiguration *_Nonnull)configuration
                          completion:(FBSDKGamingServiceResultCompletion _Nonnull)completion
                  andProgressHandler:(FBSDKGamingServiceProgressHandler _Nullable)progressHandler;

@end

NS_ASSUME_NONNULL_END

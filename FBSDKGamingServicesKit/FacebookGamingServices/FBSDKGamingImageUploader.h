/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FacebookGamingServices/FBSDKGamingServiceCompletionHandler.h>

NS_ASSUME_NONNULL_BEGIN

@class FBSDKGamingImageUploaderConfiguration;

NS_SWIFT_NAME(GamingImageUploader)
@interface FBSDKGamingImageUploader : NSObject

- (instancetype _Nonnull)init NS_SWIFT_UNAVAILABLE("Should not create instances of this class");

/**
Runs an upload to a users Gaming Media Library with the given configuration

@param configuration model object contain the content that will be uploaded
@param completion a callback that is fired dependent on the configuration.
 Fired when the upload completes or when the users returns to the caller app
 after the media dialog is shown.
 */
+ (void)uploadImageWithConfiguration:(FBSDKGamingImageUploaderConfiguration *_Nonnull)configuration
                 andResultCompletion:(FBSDKGamingServiceResultCompletion _Nonnull)completion;

/**
Runs an upload to a users Gaming Media Library with the given configuration

@param configuration model object contain the content that will be uploaded
@param completion a callback that is fired dependent on the configuration.
 Fired when the upload completes or when the users returns to the caller app
 after the media dialog is shown.
@param progressHandler an optional callback that is fired multiple times as
 bytes are transferred to Facebook.
*/
+ (void)uploadImageWithConfiguration:(FBSDKGamingImageUploaderConfiguration *_Nonnull)configuration
                          completion:(FBSDKGamingServiceResultCompletion _Nonnull)completion
                  andProgressHandler:(FBSDKGamingServiceProgressHandler _Nullable)progressHandler;

@end

NS_ASSUME_NONNULL_END

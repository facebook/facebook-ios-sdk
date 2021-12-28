/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <AvailabilityMacros.h>
#import <FacebookGamingServices/FBSDKGamingServiceCompletionHandler.h>

NS_ASSUME_NONNULL_BEGIN

@class FBSDKGamingVideoUploaderConfiguration;

NS_SWIFT_NAME(GamingVideoUploader)
@interface FBSDKGamingVideoUploader : NSObject

- (instancetype _Nonnull)init NS_SWIFT_UNAVAILABLE("Should not create instances of this class");

/**
Runs an upload to a users Gaming Media Library with the given configuration

@param configuration model object contain the content that will be uploaded
@param completion a callback that is fired when the upload completes.
*/

// UNCRUSTIFY_FORMAT_OFF
+ (void)uploadVideoWithConfiguration:(FBSDKGamingVideoUploaderConfiguration *_Nonnull)configuration
                 andResultCompletion:(FBSDKGamingServiceResultCompletion _Nonnull)completion
NS_SWIFT_NAME(uploadeVideo(configuration:completion:));
// UNCRUSTIFY_FORMAT_ON

/**
Runs an upload to a users Gaming Media Library with the given configuration

@param configuration model object contain the content that will be uploaded
@param completionHandler a callback that is fired when the upload completes.
@param progressHandler an optional callback that is fired multiple times as
 bytes are transferred to Facebook.
*/

// UNCRUSTIFY_FORMAT_OFF
+ (void)uploadVideoWithConfiguration:(FBSDKGamingVideoUploaderConfiguration *_Nonnull)configuration
                          completion:(FBSDKGamingServiceResultCompletion _Nonnull)completionHandler
                  andProgressHandler:(FBSDKGamingServiceProgressHandler _Nullable)progressHandler
NS_SWIFT_NAME(uploadVideo(configuration:completion:progressHandler:));
// UNCRUSTIFY_FORMAT_ON

@end

NS_ASSUME_NONNULL_END

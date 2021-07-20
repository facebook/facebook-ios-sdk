// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <Foundation/Foundation.h>
#import <AvailabilityMacros.h>

#import "FBSDKGamingServiceCompletionHandler.h"

@class FBSDKGamingVideoUploaderConfiguration;

NS_SWIFT_NAME(GamingVideoUploader)
@interface FBSDKGamingVideoUploader : NSObject

- (instancetype _Nonnull )init NS_SWIFT_UNAVAILABLE("Should not create instances of this class");

/**
Runs an upload to a users Gaming Media Library with the given configuration

@param configuration model object contain the content that will be uploaded
@param completionHandler a callback that is fired when the upload completes.
*/
+ (void)uploadVideoWithConfiguration:(FBSDKGamingVideoUploaderConfiguration * _Nonnull)configuration
          andResultCompletionHandler:(FBSDKGamingServiceResultCompletionHandler _Nonnull)completionHandler
DEPRECATED_MSG_ATTRIBUTE("`uploadVideoWithConfiguration:andResultCompletionHandler` is deprecated and will be removed in the next major release. It is replaced by `uploadVideoWithConfiguration:andResultCompletion`.");

/**
Runs an upload to a users Gaming Media Library with the given configuration

@param configuration model object contain the content that will be uploaded
@param completion a callback that is fired when the upload completes.
*/
+ (void)uploadVideoWithConfiguration:(FBSDKGamingVideoUploaderConfiguration * _Nonnull)configuration
                 andResultCompletion:(FBSDKGamingServiceResultCompletion _Nonnull)completion
NS_SWIFT_NAME(uploadeVideo(configuration:completion:));

/**
Runs an upload to a users Gaming Media Library with the given configuration

@param configuration model object contain the content that will be uploaded
@param completionHandler a callback that is fired when the upload completes.
@param progressHandler an optional callback that is fired multiple times as
 bytes are transferred to Facebook.
*/
+ (void)uploadVideoWithConfiguration:(FBSDKGamingVideoUploaderConfiguration * _Nonnull)configuration
                   completionHandler:(FBSDKGamingServiceResultCompletionHandler _Nonnull)completionHandler
                  andProgressHandler:(FBSDKGamingServiceProgressHandler _Nullable)progressHandler
DEPRECATED_MSG_ATTRIBUTE("`uploadVideoWithConfiguration:completionHandler:andProgressHandler:` is deprecated and will be removed in the next major release. It is replaced by `uploadVideoWithConfiguration:completion:andProgressHandler:`.");

/**
Runs an upload to a users Gaming Media Library with the given configuration

@param configuration model object contain the content that will be uploaded
@param completionHandler a callback that is fired when the upload completes.
@param progressHandler an optional callback that is fired multiple times as
 bytes are transferred to Facebook.
*/
+ (void)uploadVideoWithConfiguration:(FBSDKGamingVideoUploaderConfiguration * _Nonnull)configuration
                          completion:(FBSDKGamingServiceResultCompletion _Nonnull)completionHandler
                  andProgressHandler:(FBSDKGamingServiceProgressHandler _Nullable)progressHandler
NS_SWIFT_NAME(uploadVideo(configuration:completion:progressHandler:));

@end

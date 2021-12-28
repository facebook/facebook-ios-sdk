/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

/**
 Main completion handling of any Gaming Service (Friend Finder, Image/Video Upload).

 @param success whether the call to the service was considered a success.
 @param error the error that occured during the service call, if any.
 */
typedef void (^ FBSDKGamingServiceCompletionHandler)(BOOL success, NSError *_Nullable error)
NS_SWIFT_NAME(GamingServiceCompletionHandler);

/**
Main completion handling of any Gaming Service (Friend Finder, Image/Video Upload).

@param success whether the call to the service was considered a success.
@param result the result that was returned by the service, if any.
@param error the error that occured during the service call, if any.
*/
typedef void (^ FBSDKGamingServiceResultCompletion)(BOOL success, NSDictionary<NSString *, id> *_Nullable result, NSError *_Nullable error)
NS_SWIFT_NAME(GamingServiceResultCompletion);

/**
Main completion handling of any Gaming Service (Friend Finder, Image/Video Upload).

@param bytesSent the number of bytes sent since the last invocation
@param totalBytesSent the total number of bytes sent
@param totalBytesExpectedToSend the number of bytes that remain to be sent
*/
typedef void (^ FBSDKGamingServiceProgressHandler)(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend)
NS_SWIFT_NAME(GamingServiceProgressHandler);

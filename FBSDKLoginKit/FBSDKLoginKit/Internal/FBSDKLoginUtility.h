/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

 #import <Foundation/Foundation.h>

 #import <FBSDKLoginKit/FBSDKLoginManager.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(LoginUtility)
@interface FBSDKLoginUtility : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (NSString *)stringForAudience:(FBSDKDefaultAudience)audience;
+ (nullable NSDictionary<NSString *, id> *)queryParamsFromLoginURL:(NSURL *)url;

+ (nullable NSString *)userIDFromSignedRequest:(nullable NSString *)signedRequest;

@end

#endif

NS_ASSUME_NONNULL_END

/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class FBSDKAccessToken;
@protocol FBSDKTokenCaching;

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning UNSAFE - DO NOT USE
 */
NS_SWIFT_NAME(AccessTokenProviding)
@protocol FBSDKAccessTokenProviding

@property (class, nonatomic, copy, nullable, readonly) FBSDKAccessToken *currentAccessToken;
@property (class, nonatomic, copy, nullable) id<FBSDKTokenCaching> tokenCache;

@end

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning UNSAFE - DO NOT USE
 */
NS_SWIFT_NAME(AccessTokenSetting)
@protocol FBSDKAccessTokenSetting

@property (class, nonatomic, copy, nullable) FBSDKAccessToken *currentAccessToken;

@end

NS_ASSUME_NONNULL_END

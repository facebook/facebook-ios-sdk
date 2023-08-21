/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
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

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_AccessTokenProviding)
@protocol FBSDKAccessTokenProviding

@property (class, nullable, nonatomic, copy) FBSDKAccessToken *currentAccessToken NS_SWIFT_NAME(current);
@property (class, nullable, nonatomic, copy) id<FBSDKTokenCaching> tokenCache;

@end

NS_ASSUME_NONNULL_END

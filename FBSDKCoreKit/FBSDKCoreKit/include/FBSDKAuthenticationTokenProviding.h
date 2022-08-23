/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKTokenCaching.h>

@class FBSDKAuthenticationToken;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_AuthenticationTokenProviding)
@protocol FBSDKAuthenticationTokenProviding

@property (class, nullable, nonatomic, copy) FBSDKAuthenticationToken *currentAuthenticationToken NS_SWIFT_NAME(current);
@property (class, nullable, nonatomic, copy) id<FBSDKTokenCaching> tokenCache;

@end

NS_ASSUME_NONNULL_END

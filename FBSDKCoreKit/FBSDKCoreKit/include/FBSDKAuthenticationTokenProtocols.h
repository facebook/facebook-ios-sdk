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

NS_SWIFT_NAME(AuthenticationTokenProviding)
@protocol FBSDKAuthenticationTokenProviding

@property (class, nullable, nonatomic, readonly, copy) FBSDKAuthenticationToken *currentAuthenticationToken NS_SWIFT_NAME(current);
@property (class, nullable, nonatomic, copy) id<FBSDKTokenCaching> tokenCache;

@end

NS_SWIFT_NAME(AuthenticationTokenSetting)
@protocol FBSDKAuthenticationTokenSetting

@property (class, nullable, nonatomic, copy) FBSDKAuthenticationToken *currentAuthenticationToken NS_SWIFT_NAME(current);

@end

NS_ASSUME_NONNULL_END

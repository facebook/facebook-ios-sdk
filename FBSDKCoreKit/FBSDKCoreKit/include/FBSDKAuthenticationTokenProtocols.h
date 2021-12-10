/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKAuthenticationToken.h>
#import <FBSDKCoreKit/FBSDKTokenCaching.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AuthenticationTokenProviding)
@protocol FBSDKAuthenticationTokenProviding

@property (class, nullable, nonatomic, readonly, copy) FBSDKAuthenticationToken *currentAuthenticationToken;
@property (class, nullable, nonatomic, copy) id<FBSDKTokenCaching> tokenCache;

@end

NS_SWIFT_NAME(AuthenticationTokenSetting)
@protocol FBSDKAuthenticationTokenSetting

@property (class, nullable, nonatomic, copy) FBSDKAuthenticationToken *currentAuthenticationToken;

@end

NS_ASSUME_NONNULL_END

/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKAuthenticationToken.h>

#import "FBSDKTokenCaching.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKAuthenticationToken (Internal)

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithTokenString:(NSString *)tokenString
                              nonce:(NSString *)nonce
                        graphDomain:(NSString *)graphDomain;
+ (void)resetTokenCache;

@end

NS_ASSUME_NONNULL_END

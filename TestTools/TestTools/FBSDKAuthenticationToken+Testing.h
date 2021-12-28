/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@import FBSDKCoreKit;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKAuthenticationToken (TestTools)

- (instancetype)initWithTokenString:(NSString *)tokenString
                              nonce:(NSString *)nonce;

- (instancetype)initWithTokenString:(NSString *)tokenString
                              nonce:(NSString *)nonce
                        graphDomain:(NSString *)graphDomain;

+ (void)resetCurrentAuthenticationTokenCache;

@end

NS_ASSUME_NONNULL_END

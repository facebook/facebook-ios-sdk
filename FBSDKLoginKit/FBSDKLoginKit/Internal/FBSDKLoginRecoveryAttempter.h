/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKLoginProviding.h"
#import "TargetConditionals.h"

#if !TARGET_OS_TV

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(LoginRecoveryAttempter)
@interface FBSDKLoginRecoveryAttempter : NSObject <FBSDKErrorRecoveryAttempting>

@property (nonatomic) id<FBSDKLoginProviding> loginManager;
@property (nonatomic) Class<FBSDKAccessTokenProviding> accessTokenProvider;

- (instancetype)initWithLoginManager:(id<FBSDKLoginProviding>)loginManager
                 accessTokenProvider:(Class<FBSDKAccessTokenProviding>)accessTokenProvider;

@end

NS_ASSUME_NONNULL_END

#endif

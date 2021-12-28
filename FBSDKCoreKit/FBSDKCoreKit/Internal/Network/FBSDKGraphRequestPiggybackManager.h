/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKGraphRequestConnection.h>

#import "FBSDKGraphRequestPiggybackManaging.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(GraphRequestPiggybackManager)
@interface FBSDKGraphRequestPiggybackManager : NSObject <FBSDKGraphRequestPiggybackManaging>

+ (void)addRefreshPiggybackIfStale:(id<FBSDKGraphRequestConnecting>)connection;

+ (void)addServerConfigurationPiggyback:(id<FBSDKGraphRequestConnecting>)connection;

@end

NS_ASSUME_NONNULL_END

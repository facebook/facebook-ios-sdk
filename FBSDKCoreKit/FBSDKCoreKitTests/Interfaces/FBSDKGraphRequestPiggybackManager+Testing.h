/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKGraphRequestPiggybackManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKGraphRequestPiggybackManager (Testing)

@property (class, nullable, nonatomic) Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting> tokenWallet;

+ (id<FBSDKSettings>)settings;
+ (id<FBSDKServerConfigurationProviding>)serverConfiguration;
+ (id<FBSDKGraphRequestFactory>)graphRequestFactory;
+ (int)_tokenRefreshThresholdInSeconds;
+ (int)_tokenRefreshRetryInSeconds;
+ (BOOL)_safeForPiggyback:(FBSDKGraphRequest *)request;
+ (void)_setLastRefreshTry:(NSDate *)date;
+ (void)reset;

@end

NS_ASSUME_NONNULL_END

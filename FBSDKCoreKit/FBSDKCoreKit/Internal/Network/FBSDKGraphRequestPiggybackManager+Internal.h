/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKGraphRequestPiggybackManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKAccessTokenProviding;
@protocol FBSDKAccessTokenSetting;
@protocol FBSDKGraphRequestFactory;
@protocol FBSDKServerConfigurationProviding;
@protocol FBSDKSettings;

@interface FBSDKGraphRequestPiggybackManager (Internal)

@property (class, nullable, nonatomic) NSDate *lastRefreshTry;
@property (class, nonatomic, readonly) int tokenRefreshThresholdInSeconds;
@property (class, nonatomic, readonly) int tokenRefreshRetryInSeconds;

@property (class, nullable, nonatomic) Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting> tokenWallet;
@property (class, nullable, nonatomic) id<FBSDKSettings> settings;
@property (class, nullable, nonatomic) id<FBSDKServerConfigurationProviding> serverConfigurationProvider;
@property (class, nullable, nonatomic) id<FBSDKGraphRequestFactory> graphRequestFactory;

+ (void)configureWithTokenWallet:(Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting>)tokenWallet
                        settings:(id<FBSDKSettings>)settings
     serverConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider
             graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory;

+ (BOOL)isRequestSafeForPiggyback:(id<FBSDKGraphRequest>)request;
+ (void)reset;

@end

NS_ASSUME_NONNULL_END

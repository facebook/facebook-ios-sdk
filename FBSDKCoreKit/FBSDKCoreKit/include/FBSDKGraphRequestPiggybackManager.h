/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKGraphRequestPiggybackManaging.h>

@protocol FBSDKAccessTokenProviding;
@protocol FBSDKSettings;
@protocol FBSDKServerConfigurationProviding;
@protocol FBSDKGraphRequestFactory;
@protocol FBSDKGraphRequest;
@protocol FBSDKGraphRequestConnecting;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_GraphRequestPiggybackManager)
@interface FBSDKGraphRequestPiggybackManager : NSObject <FBSDKGraphRequestPiggybackManaging>

@property (nullable, nonatomic) NSDate *lastRefreshTry;
@property (nonatomic, readonly) int tokenRefreshThresholdInSeconds;
@property (nonatomic, readonly) int tokenRefreshRetryInSeconds;

@property (nonatomic) Class<FBSDKAccessTokenProviding> tokenWallet;
@property (nonatomic) id<FBSDKSettings> settings;
@property (nonatomic) id<FBSDKServerConfigurationProviding> serverConfigurationProvider;
@property (nonatomic) id<FBSDKGraphRequestFactory> graphRequestFactory;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithTokenWallet:(Class<FBSDKAccessTokenProviding>)tokenWallet
                           settings:(id<FBSDKSettings>)settings
        serverConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider
                graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory;

// UNCRUSTIFY_FORMAT_OFF
- (BOOL)isRequestSafeForPiggyback:(id<FBSDKGraphRequest>)request
NS_SWIFT_NAME(isRequestSafeForPiggyback(_:));
// UNCRUSTIFY_FORMAT_ON

- (void)addRefreshPiggybackIfStale:(id<FBSDKGraphRequestConnecting>)connection;

- (void)addServerConfigurationPiggyback:(id<FBSDKGraphRequestConnecting>)connection;

@end

NS_ASSUME_NONNULL_END

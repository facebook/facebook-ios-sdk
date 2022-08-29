/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#define DATA_PROCESSING_OPTIONS         @"data_processing_options"
#define DATA_PROCESSING_OPTIONS_COUNTRY @"data_processing_options_country"
#define DATA_PROCESSING_OPTIONS_STATE   @"data_processing_options_state"

@protocol FBSDKTokenCaching;
@protocol FBSDKDataPersisting;
@protocol FBSDKAppEventsConfigurationProviding;
@protocol FBSDKInfoDictionaryProviding;
@protocol FBSDKEventLogging;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKSettings (Internal) <FBSDKSettingsLogging>

@property (class, nullable, nonatomic, readonly, copy) NSString *graphAPIDebugParamValue;
@property (nonatomic) BOOL shouldUseTokenOptimizations;

+ (nullable NSObject<FBSDKTokenCaching> *)tokenCache;

+ (void)setTokenCache:(nullable NSObject<FBSDKTokenCaching> *)tokenCache;

- (FBSDKAdvertisingTrackingStatus)advertisingTrackingStatus;

- (void)setAdvertiserTrackingStatus:(FBSDKAdvertisingTrackingStatus)status;

- (void)recordSetAdvertiserTrackingEnabled;

+ (BOOL)isSetATETimeExceedsInstallTime;

+ (NSDate *_Nullable)getInstallTimestamp;

+ (NSDate *_Nullable)getSetAdvertiserTrackingEnabledTimestamp;

- (void)recordInstall;

- (void)logWarnings;

- (void)logIfSDKSettingsChanged;

- (BOOL)isEventDelayTimerExpired;

@end

NS_ASSUME_NONNULL_END

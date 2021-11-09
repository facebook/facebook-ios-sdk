/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKClientTokenProviding.h"

#define DATA_PROCESSING_OPTIONS         @"data_processing_options"
#define DATA_PROCESSING_OPTIONS_COUNTRY @"data_processing_options_country"
#define DATA_PROCESSING_OPTIONS_STATE   @"data_processing_options_state"

#import "FBSDKClientTokenProviding.h"

@protocol FBSDKTokenCaching;
@protocol FBSDKDataPersisting;
@protocol FBSDKAppEventsConfigurationProviding;
@protocol FBSDKInfoDictionaryProviding;
@protocol FBSDKEventLogging;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKSettings (Internal) <FBSDKClientTokenProviding, FBSDKSettingsLogging>

@property (class, nullable, nonatomic, readonly, copy) NSString *graphAPIDebugParamValue;
@property (nonatomic) BOOL shouldUseTokenOptimizations;
@property (nullable, nonatomic) NSDictionary<NSString *, id> *persistableDataProcessingOptions;

// UNCRUSTIFY_FORMAT_OFF
+ (void)      configureWithStore:(nonnull id<FBSDKDataPersisting>)store
  appEventsConfigurationProvider:(nonnull id<FBSDKAppEventsConfigurationProviding>)provider
          infoDictionaryProvider:(nonnull id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider
                     eventLogger:(nonnull id<FBSDKEventLogging>)eventLogger
NS_SWIFT_NAME(configure(store:appEventsConfigurationProvider:infoDictionaryProvider:eventLogger:));
// UNCRUSTIFY_FORMAT_ON

+ (nullable NSObject<FBSDKTokenCaching> *)tokenCache;

+ (void)setTokenCache:(nullable NSObject<FBSDKTokenCaching> *)tokenCache;

+ (FBSDKAdvertisingTrackingStatus)advertisingTrackingStatus;

+ (void)setAdvertiserTrackingStatus:(FBSDKAdvertisingTrackingStatus)status;

+ (BOOL)isDataProcessingRestricted;

+ (void)recordSetAdvertiserTrackingEnabled;

+ (BOOL)isEventDelayTimerExpired;

+ (BOOL)isSetATETimeExceedsInstallTime;

+ (NSDate *_Nullable)getInstallTimestamp;

+ (NSDate *_Nullable)getSetAdvertiserTrackingEnabledTimestamp;

- (void)recordInstall;

- (void)logWarnings;

- (void)logIfSDKSettingsChanged;

@end

NS_ASSUME_NONNULL_END

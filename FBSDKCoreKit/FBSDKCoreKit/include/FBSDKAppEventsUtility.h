/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKAppEventParametersExtracting.h>
#import <FBSDKCoreKit/FBSDKAppEventsFlushReason.h>
#import <FBSDKCoreKit/FBSDKAppEventsUtilityProtocol.h>
#import <FBSDKCoreKit/FBSDKLoggingNotifying.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_AppEventsUtility)
@interface FBSDKAppEventsUtility : NSObject <FBSDKAdvertiserIDProviding, FBSDKAppEventDropDetermining, FBSDKAppEventParametersExtracting, FBSDKAppEventsUtility, FBSDKLoggingNotifying>

#if !DEBUG
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
#endif

@property (class, nonatomic) FBSDKAppEventsUtility *shared;
@property (nullable, nonatomic, readonly, copy) NSString *advertiserID;
@property (nonatomic, readonly) BOOL isDebugBuild;
@property (nonatomic, readonly) BOOL shouldDropAppEvents;
@property (nullable, nonatomic) id<FBSDKAppEventsConfigurationProviding> appEventsConfigurationProvider;
@property (nullable, nonatomic) id<FBSDKDeviceInformationProviding> deviceInformationProvider;
@property (nullable, nonatomic) id<FBSDKSettings> settings;
@property (nullable, nonatomic) id<FBSDKInternalUtility> internalUtility;
@property (nullable, nonatomic) id<FBSDKErrorCreating> errorFactory;
@property (nullable, nonatomic) id<FBSDKDataPersisting> dataStore;

- (BOOL)isSensitiveUserData:(NSString *)text;
- (BOOL)isStandardEvent:(nullable NSString *)event;

// UNCRUSTIFY_FORMAT_OFF
- (void)configureWithAppEventsConfigurationProvider:(id<FBSDKAppEventsConfigurationProviding>)appEventsConfigurationProvider
                          deviceInformationProvider:(id<FBSDKDeviceInformationProviding>)deviceInformationProvider
                                           settings:(id<FBSDKSettings>)settings
                                    internalUtility:(id<FBSDKInternalUtility>)internalUtility
                                       errorFactory:(id<FBSDKErrorCreating>)errorFactory
                                          dataStore:(id<FBSDKDataPersisting>)dataStore
NS_SWIFT_NAME(configure(appEventsConfigurationProvider:deviceInformationProvider:settings:internalUtility:errorFactory:dataStore:));
// UNCRUSTIFY_FORMAT_ON

#if DEBUG
- (void)reset;
#endif

@end

NS_ASSUME_NONNULL_END

/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKAdvertiserIDProviding.h"
#import "FBSDKAppEventDropDetermining.h"
#import "FBSDKAppEventParametersExtracting.h"
#import "FBSDKAppEventsConfigurationProviding.h"
#import <FBSDKCoreKit/FBSDKAppEventsFlushReason.h>
#import "FBSDKAppEventsUtilityProtocol.h"
#import "FBSDKDeviceInformationProviding.h"
#import "FBSDKLoggingNotifying.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AppEventsUtility)
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

- (BOOL)isSensitiveUserData:(NSString *)text;
- (BOOL)isStandardEvent:(nullable NSString *)event;

// UNCRUSTIFY_FORMAT_OFF
- (void)configureWithAppEventsConfigurationProvider:(id<FBSDKAppEventsConfigurationProviding>)appEventsConfigurationProvider
                          deviceInformationProvider:(id<FBSDKDeviceInformationProviding>)deviceInformationProvider
                                           settings:(id<FBSDKSettings>)settings
                                    internalUtility:(id<FBSDKInternalUtility>)internalUtility
                                       errorFactory:(id<FBSDKErrorCreating>)errorFactory
NS_SWIFT_NAME(configure(appEventsConfigurationProvider:deviceInformationProvider:settings:internalUtility:errorFactory:));
// UNCRUSTIFY_FORMAT_ON

#if DEBUG
- (void)reset;
#endif

@end

NS_ASSUME_NONNULL_END

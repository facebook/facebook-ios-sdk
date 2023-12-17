/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <FBAEMKit/FBAEMKit-Swift.h>
#import <FBSDKCoreKit/FBSDKAppEventsReporter.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_SKAdNetworkReporterV2)
@interface FBSDKSKAdNetworkReporterV2 : NSObject <FBSKAdNetworkReporting, FBSDKAppEventsReporter>

@property (nonatomic) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (nonatomic) id<FBSDKDataPersisting> dataStore;
@property (nonatomic) Class<FBSDKConversionValueUpdating> conversionValueUpdater;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

// UNCRUSTIFY_FORMAT_OFF
- (instancetype)initWithGraphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                                  dataStore:(id<FBSDKDataPersisting>)dataStore
                     conversionValueUpdater:(Class<FBSDKConversionValueUpdating>)conversionValueUpdater
NS_SWIFT_NAME(init(graphRequestFactory:dataStore:conversionValueUpdater:));
// UNCRUSTIFY_FORMAT_ON

- (void)enable;

- (void)recordAndUpdateEvent:(NSString *)event
                    currency:(nullable NSString *)currency
                       value:(nullable NSNumber *)value;

- (BOOL)shouldCutoff;

- (BOOL)isReportingEvent:(NSString *)event;

- (void)checkAndRevokeTimer;

@end

NS_ASSUME_NONNULL_END

#endif

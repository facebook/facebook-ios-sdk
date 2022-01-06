/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import <FBAEMKit/FBAEMKit.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKAppEventsReporter.h"
#import "FBSDKConversionValueUpdating.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(SKAdNetworkReporter)
@interface FBSDKSKAdNetworkReporter : NSObject <FBSKAdNetworkReporting, FBSDKAppEventsReporter>

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

@end

NS_ASSUME_NONNULL_END

#endif

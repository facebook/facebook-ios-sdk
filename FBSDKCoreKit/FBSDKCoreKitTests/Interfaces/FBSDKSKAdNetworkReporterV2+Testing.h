/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKSKAdNetworkConversionConfiguration.h"

typedef void (^FBSDKSKAdNetworkReporterBlock)(void);

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKSKAdNetworkReporterV2 (Testing)

@property (nonatomic) BOOL isSKAdNetworkReportEnabled;
@property (nonnull, nonatomic) NSMutableArray<FBSDKSKAdNetworkReporterBlock> *completionBlocks;
@property (nonnull, nonatomic) dispatch_queue_t serialQueue;
@property (nullable, nonatomic) FBSDKSKAdNetworkConversionConfiguration *configuration;
@property (nonnull, nonatomic) NSDate *configRefreshTimestamp;
@property (nonatomic) NSInteger conversionValue;
@property (nonatomic) NSString *coarseConversionValue;
@property (nonatomic) NSDate *timestamp;
@property (nonatomic) NSDate *coarseCVUpdateTimestamp;
@property (nonnull, nonatomic) NSMutableSet<NSString *> *recordedEvents;
@property (nonnull, nonatomic) NSMutableSet<NSString *> *recordedCoarseEvents;
@property (nonnull, nonatomic) NSMutableDictionary<NSString *, id> *recordedValues;
@property (nonnull, nonatomic) NSMutableDictionary<NSString *, id> *recordedCoarseValues;

- (void)_loadReportData;
- (void)_recordAndUpdateEvent:(NSString *)event
                     currency:(nullable NSString *)currency
                        value:(nullable NSNumber *)value;
- (void)_updateConversionValue:(NSInteger)value;
- (void)_updateCoarseConversionValue:(NSString *)value;


- (void)setSKAdNetworkReportEnabled:(BOOL)enabled;

- (void)_loadConfigurationWithBlock:(FBSDKSKAdNetworkReporterBlock)block;
- (void)configureWithGraphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                                   store:(id<FBSDKDataPersisting>)store;
- (NSInteger)_getCurrentPostbackSequenceIndex;

@end

NS_ASSUME_NONNULL_END

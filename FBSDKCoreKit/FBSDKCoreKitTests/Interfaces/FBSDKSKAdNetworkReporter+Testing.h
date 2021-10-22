/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKSKAdNetworkConversionConfiguration.h"
#import "FBSDKSKAdNetworkReporter.h"

typedef void (^FBSDKSKAdNetworkReporterBlock)(void);

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKSKAdNetworkReporter (Testing)

@property (nonatomic) BOOL isSKAdNetworkReportEnabled;
@property (nonnull, nonatomic) NSMutableArray<FBSDKSKAdNetworkReporterBlock> *completionBlocks;
@property (nonnull, nonatomic) dispatch_queue_t serialQueue;
@property (nullable, nonatomic) FBSDKSKAdNetworkConversionConfiguration *config;
@property (nonnull, nonatomic) NSDate *configRefreshTimestamp;
@property (nonatomic) NSInteger conversionValue;
@property (nonatomic) NSDate *timestamp;
@property (nonnull, nonatomic) NSMutableSet<NSString *> *recordedEvents;
@property (nonnull, nonatomic) NSMutableDictionary<NSString *, id> *recordedValues;

@property (nonnull, nonatomic, readonly) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (nonnull, nonatomic, readonly) id<FBSDKDataPersisting> store;
@property (nonnull, nonatomic, readonly) Class<FBSDKConversionValueUpdating> conversionValueUpdatable;

- (void)setConfiguration:(FBSDKSKAdNetworkConversionConfiguration *)configuration;
- (void)_loadReportData;
- (void)_recordAndUpdateEvent:(NSString *)event
                     currency:(nullable NSString *)currency
                        value:(nullable NSNumber *)value;
- (void)_updateConversionValue:(NSInteger)value;

- (void)setSKAdNetworkReportEnabled:(BOOL)enabled;

- (void)_loadConfigurationWithBlock:(FBSDKSKAdNetworkReporterBlock)block;
- (void)configureWithGraphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                                   store:(id<FBSDKDataPersisting>)store;

- (instancetype)initWithGraphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                                      store:(id<FBSDKDataPersisting>)store
                   conversionValueUpdatable:(Class<FBSDKConversionValueUpdating>)conversionValueUpdatable;

@end

NS_ASSUME_NONNULL_END

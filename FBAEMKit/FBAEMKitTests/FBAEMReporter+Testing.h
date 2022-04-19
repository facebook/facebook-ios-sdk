/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBAEMReporter.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^FBAEMReporterBlock)(NSError *_Nullable);

@interface FBAEMReporter (Testing)

@property (class, nonatomic, assign) BOOL isLoadingConfiguration;
@property (class, nonatomic) dispatch_queue_t queue;
@property (class, nonatomic) NSDate *timestamp;
@property (class, nonatomic) BOOL isEnabled;
@property (class, nonatomic) BOOL isConversionFilteringEnabled;
@property (class, nonatomic) BOOL isCatalogMatchingEnabled;
@property (class, nonatomic) NSMutableDictionary<NSString *, NSMutableArray<FBAEMConfiguration *> *> *configs;
@property (class, nonatomic) NSMutableArray<FBAEMInvocation *> *invocations;
@property (class, nonatomic) NSMutableArray<FBAEMReporterBlock> *completionBlocks;
@property (class, nonatomic) NSString *reportFilePath;
@property (class, nullable, nonatomic) NSDate *minAggregationRequestTimestamp;
@property (class, nullable, nonatomic) id<FBAEMNetworking> networker;
@property (class, nullable, nonatomic) NSString *analyticsAppID;
@property (class, nullable, nonatomic) id<FBSKAdNetworkReporting> reporter;
@property (class, nullable, nonatomic) id<FBSDKDataPersisting> store;

+ (void)configureWithNetworker:(nullable id<FBAEMNetworking>)networker
                         appID:(nullable NSString *)appID
                      reporter:(nullable id<FBSKAdNetworkReporting>)reporter
                analyticsAppID:(nullable NSString *)analyticsAppID
                         store:(nullable id<FBSDKDataPersisting>)store;

+ (void)enable;

+ (nullable FBAEMInvocation *)parseURL:(nullable NSURL *)url;

+ (void)_loadConfigurationWithRefreshForced:(BOOL)forced
                                      block:(nullable FBAEMReporterBlock)block;

+ (void)_loadCatalogOptimizationWithInvocation:(FBAEMInvocation *)invocation
                                     contentID:(nullable NSString *)contentID
                                         block:(dispatch_block_t)block;

+ (BOOL)_isContentOptimized:(id _Nullable)result;

+ (BOOL)_shouldReportConversionInCatalogLevel:(FBAEMInvocation *)invocation
                                        event:(NSString *)event;

+ (NSDictionary<NSString *, id> *)_catalogRequestParameters:(nullable NSString *)catalogID
                                                  contentID:(nullable NSString *)contentID;

+ (nullable FBAEMInvocation *)_attributedInvocation:(NSArray<FBAEMInvocation *> *)invocations
                                              Event:(NSString *)event
                                           currency:(nullable NSString *)currency
                                              value:(nullable NSNumber *)value
                                         parameters:(nullable NSDictionary<NSString *, id> *)parameters
                                            configs:(NSDictionary<NSString *, NSMutableArray<FBAEMConfiguration *> *> *)configs;

+ (BOOL)_isDoubleCounting:(FBAEMInvocation *)invocation
                    event:(NSString *)event;

+ (void)_sendDebuggingRequest:(FBAEMInvocation *)invocation;

+ (NSDictionary<NSString *, id> *)_debuggingRequestParameters:(FBAEMInvocation *)invocation;

+ (void)_sendAggregationRequest;

+ (NSDictionary<NSString *, id> *)_requestParameters;

+ (NSDictionary<NSString *, id> *)_aggregationRequestParameters:(FBAEMInvocation *)invocation;

+ (BOOL)_isConfigRefreshTimestampValid;

+ (BOOL)_shouldRefreshWithIsForced:(BOOL)isForced;

+ (NSMutableDictionary<NSString *, NSMutableArray<FBAEMConfiguration *> *> *)_loadConfigs;

+ (void)_addConfigs:(nullable NSArray<NSDictionary<NSString *, id> *> *)configs;

+ (NSMutableArray<FBAEMInvocation *> *)_loadReportData;

+ (void)_saveReportData;

+ (BOOL)_shouldDelayAggregationRequest;

+ (nullable NSDate *)_loadMinAggregationRequestTimestamp;

+ (void)_updateAggregationRequestTimestamp:(NSTimeInterval)timestamp;

+ (void)_clearCache;

+ (void)_clearConfigs;

+ (void)reset;

@end

NS_ASSUME_NONNULL_END

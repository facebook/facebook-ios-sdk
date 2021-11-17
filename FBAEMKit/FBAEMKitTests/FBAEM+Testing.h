/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBAEMAdvertiserMultiEntryRule.h"
#import "FBAEMAdvertiserRuleFactory.h"
#import "FBAEMAdvertiserRuleMatching.h"
#import "FBAEMAdvertiserSingleEntryRule.h"
#import "FBAEMConfiguration.h"
#import "FBAEMEvent.h"
#import "FBAEMInvocation.h"
#import "FBAEMReporter.h"
#import "FBAEMRule.h"
#import "FBAEMUtility.h"

typedef void (^FBAEMReporterBlock)(NSError *_Nullable);

NS_ASSUME_NONNULL_BEGIN

@interface FBAEMConfiguration (Testing)

+ (nullable NSArray<FBAEMRule *> *)parseRules:(nullable NSArray<NSDictionary<NSString *, id> *> *)rules;

+ (NSSet<NSString *> *)getEventSetFromRules:(NSArray<FBAEMRule *> *)rules;

+ (NSSet<NSString *> *)getCurrencySetFromRules:(NSArray<FBAEMRule *> *)rules;

+ (id<FBAEMAdvertiserRuleProviding>)ruleProvider;

@end

@interface FBAEMInvocation (Testing)

@property (nonatomic, copy) NSString *campaignID;
@property (nonatomic, assign) NSInteger conversionValue;
@property (nullable, nonatomic, copy) NSString *ACSSharedSecret;
@property (nullable, nonatomic, copy) NSString *ACSConfigID;
@property (nullable, nonatomic, copy) NSString *catalogID;

- (nullable instancetype)initWithCampaignID:(NSString *)campaignID
                                   ACSToken:(NSString *)ACSToken
                            ACSSharedSecret:(nullable NSString *)ACSSharedSecret
                                ACSConfigID:(nullable NSString *)ACSConfigID
                                 businessID:(nullable NSString *)businessID
                                  catalogID:(nullable NSString *)catalogID
                                 isTestMode:(BOOL)isTestMode
                                    hasSKAN:(BOOL)hasSKAN;

- (nullable instancetype)initWithCampaignID:(NSString *)campaignID
                                   ACSToken:(NSString *)ACSToken
                            ACSSharedSecret:(nullable NSString *)ACSSharedSecret
                                ACSConfigID:(nullable NSString *)ACSConfigID
                                 businessID:(nullable NSString *)businessID
                                  catalogID:(nullable NSString *)catalogID
                                  timestamp:(nullable NSDate *)timestamp
                                 configMode:(nullable NSString *)configMode
                                   configID:(NSInteger)configID
                             recordedEvents:(nullable NSMutableSet<NSString *> *)recordedEvents
                             recordedValues:(nullable NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *)recordedValues
                            conversionValue:(NSInteger)conversionValue
                                   priority:(NSInteger)priority
                        conversionTimestamp:(nullable NSDate *)conversionTimestamp
                               isAggregated:(BOOL)isAggregated
                                 isTestMode:(BOOL)isTestMode
                                    hasSKAN:(BOOL)hasSKAN;

- (nullable NSDictionary<NSString *, id> *)processedParameters:(nullable NSDictionary<NSString *, id> *)parameters;

- (nullable FBAEMConfiguration *)_findConfig:(nullable NSDictionary<NSString *, NSArray<FBAEMConfiguration *> *> *)configs;

- (NSArray<FBAEMConfiguration *> *)_getConfigList:(NSString *)configMode
                                          configs:(nullable NSDictionary<NSString *, NSArray<FBAEMConfiguration *> *> *)configs;

- (nullable NSString *)getHMAC:(NSInteger)delay;

- (nullable NSData *)decodeBase64UrlSafeString:(NSString *)base64UrlSafeString;

- (void)_setConfig:(FBAEMConfiguration *)config;

- (void)setRecordedEvents:(NSMutableSet<NSString *> *)recordedEvents;

- (void)setRecordedValues:(NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *)recordedValues;

- (void)setPriority:(NSInteger)priority;

- (void)setConfigID:(NSInteger)configID;

- (void)setBusinessID:(NSString *_Nullable)businessID;

- (void)setConversionTimestamp:(NSDate *_Nonnull)conversionTimestamp;

- (void)reset;

@end

@interface FBAEMReporter (Testing)

@property (class, nonatomic, assign) BOOL isLoadingConfiguration;
@property (class, nonatomic) dispatch_queue_t queue;
@property (class, nonatomic) NSDate *timestamp;
@property (class, nonatomic) BOOL isEnabled;
@property (class, nonatomic) BOOL isCatalogReportEnabled;
@property (class, nonatomic) NSMutableDictionary<NSString *, NSMutableArray<FBAEMConfiguration *> *> *configs;
@property (class, nonatomic) NSMutableArray<FBAEMInvocation *> *invocations;
@property (class, nonatomic) NSMutableArray<FBAEMReporterBlock> *completionBlocks;
@property (class, nonatomic) NSString *reportFilePath;
@property (class, nonatomic) id<FBAEMNetworking> networker;
@property (class, nullable, nonatomic) id<FBAEMNetworking> catalogNetworker;
@property (class, nonatomic) id<FBSKAdNetworkReporting> reporter;

+ (void)enable;

+ (nullable FBAEMInvocation *)parseURL:(nullable NSURL *)url;

+ (void)_loadConfigurationWithBlock:(nullable FBAEMReporterBlock)block;

+ (void)_loadCatalogOptimizationWithInvocation:(FBAEMInvocation *)invocation
                                     contentID:(nullable NSString *)contentID
                                         block:(dispatch_block_t)block;

+ (BOOL)_isContentOptimized:(id _Nullable)result;

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

+ (BOOL)_shouldRefresh;

+ (NSMutableDictionary<NSString *, NSMutableArray<FBAEMConfiguration *> *> *)_loadConfigs;

+ (void)_addConfigs:(nullable NSArray<NSDictionary<NSString *, id> *> *)configs;

+ (NSMutableArray<FBAEMInvocation *> *)_loadReportData;

+ (void)_saveReportData;

+ (void)_clearCache;

+ (void)reset;

@end

@interface FBAEMAdvertiserRuleFactory (Testing)

- (nullable FBAEMAdvertiserMultiEntryRule *)createMultiEntryRuleWithDict:(NSDictionary<NSString *, id> *)dict;

- (nullable FBAEMAdvertiserSingleEntryRule *)createSingleEntryRuleWithDict:(NSDictionary<NSString *, id> *)dict;

- (nullable NSString *)primaryKeyForRule:(NSDictionary<NSString *, id> *)rule;

- (FBAEMAdvertiserRuleOperator)getOperator:(NSDictionary<NSString *, id> *)rule;

- (BOOL)isOperatorForMultiEntryRule:(FBAEMAdvertiserRuleOperator)op;

@end

@interface FBAEMAdvertiserSingleEntryRule (Testing)

- (BOOL)isMatchedWithStringValue:(nullable NSString *)stringValue
                  numericalValue:(nullable NSNumber *)numericalValue;

- (BOOL)isMatchedWithAsteriskParam:(NSString *)param
                   eventParameters:(NSDictionary<NSString *, id> *)eventParams
                         paramPath:(NSArray<NSString *> *)paramPath;

- (BOOL)isRegexMatch:(NSString *)stringValue;

- (BOOL)isAnyOf:(NSArray<NSString *> *)arrayCondition
    stringValue:(NSString *)stringValue
     ignoreCase:(BOOL)ignoreCase;

- (void)setOperator:(FBAEMAdvertiserRuleOperator)op;

@end

NS_ASSUME_NONNULL_END

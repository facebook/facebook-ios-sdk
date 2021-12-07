/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBAEMInvocation.h"

NS_ASSUME_NONNULL_BEGIN

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

NS_ASSUME_NONNULL_END

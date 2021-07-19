// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "FBSDKAEMAdvertiserMultiEntryRule.h"
#import "FBSDKAEMAdvertiserRuleFactory.h"
#import "FBSDKAEMAdvertiserRuleMatching.h"
#import "FBSDKAEMAdvertiserSingleEntryRule.h"
#import "FBSDKAEMConfiguration.h"
#import "FBSDKAEMEvent.h"
#import "FBSDKAEMInvocation.h"
#import "FBSDKAEMReporter.h"
#import "FBSDKAEMRule.h"
#import "FBSDKCoreKit+internal.h"
#import "FBSDKSwizzler+Swizzling.h"
#import "FBSDKSwizzling.h"
#import "FBSDKTestCoder.h"

typedef void (^FBSDKAEMReporterBlock)(NSError *_Nullable);

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKAEMConfiguration (Testing)

+ (nullable NSArray<FBSDKAEMRule *> *)parseRules:(nullable NSArray<NSDictionary<NSString *, id> *> *)rules;

+ (NSSet<NSString *> *)getEventSetFromRules:(NSArray<FBSDKAEMRule *> *)rules;

+ (NSSet<NSString *> *)getCurrencySetFromRules:(NSArray<FBSDKAEMRule *> *)rules;

+ (id<FBSDKAEMAdvertiserRuleProviding>)ruleProvider;

@end

@interface FBSDKAEMInvocation (Testing)

@property (nonatomic, copy) NSString *campaignID;
@property (nonatomic, assign) NSInteger conversionValue;
@property (nullable, nonatomic, copy) NSString *ACSSharedSecret;
@property (nullable, nonatomic, copy) NSString *ACSConfigID;

- (nullable instancetype)initWithCampaignID:(NSString *)campaignID
                                   ACSToken:(NSString *)ACSToken
                            ACSSharedSecret:(nullable NSString *)ACSSharedSecret
                                ACSConfigID:(nullable NSString *)ACSConfigID
                                 businessID:(nullable NSString *)businessID;

- (nullable instancetype)initWithCampaignID:(NSString *)campaignID
                                   ACSToken:(NSString *)ACSToken
                            ACSSharedSecret:(nullable NSString *)ACSSharedSecret
                                ACSConfigID:(nullable NSString *)ACSConfigID
                                 businessID:(nullable NSString *)businessID
                                  timestamp:(nullable NSDate *)timestamp
                                 configMode:(nullable NSString *)configMode
                                   configID:(NSInteger)configID
                             recordedEvents:(nullable NSMutableSet<NSString *> *)recordedEvents
                             recordedValues:(nullable NSMutableDictionary<NSString *, NSMutableDictionary *> *)recordedValues
                            conversionValue:(NSInteger)conversionValue
                                   priority:(NSInteger)priority
                        conversionTimestamp:(nullable NSDate *)conversionTimestamp
                               isAggregated:(BOOL)isAggregated;

- (nullable FBSDKAEMConfiguration *)_findConfig:(nullable NSDictionary<NSString *, NSArray<FBSDKAEMConfiguration *> *> *)configs;

- (nullable NSString *)getHMAC:(NSInteger)delay;

- (nullable NSData *)decodeBase64UrlSafeString:(NSString *)base64UrlSafeString;

- (void)_setConfig:(FBSDKAEMConfiguration *)config;

- (void)setRecordedEvents:(NSMutableSet<NSString *> *)recordedEvents;

- (void)setRecordedValues:(NSMutableDictionary<NSString *, NSMutableDictionary *> *)recordedValues;

- (void)setPriority:(NSInteger)priority;

- (void)setConfigID:(NSInteger)configID;

- (void)setBusinessID:(NSString *_Nullable)businessID;

- (void)setConversionTimestamp:(NSDate *_Nonnull)conversionTimestamp;

- (void)reset;

@end

@interface FBSDKAEMReporter (Testing)

@property (class, nonatomic, assign) BOOL isLoadingConfiguration;
@property (class, nonatomic) dispatch_queue_t queue;
@property (class, nonatomic) NSDate *timestamp;
@property (class, nonatomic) BOOL isEnabled;
@property (class, nonatomic) NSMutableDictionary<NSString *, NSMutableArray<FBSDKAEMConfiguration *> *> *configs;
@property (class, nonatomic) NSMutableArray<FBSDKAEMInvocation *> *invocations;
@property (class, nonatomic) NSMutableArray<FBSDKAEMReporterBlock> *completionBlocks;
@property (class, nonatomic) NSString *reportFilePath;

+ (void)enable;

+ (void)configureWithRequestProvider:(id<FBSDKGraphRequestProviding>)requestProvider;

+ (nullable FBSDKAEMInvocation *)parseURL:(nullable NSURL *)url;

+ (void)_loadConfigurationWithBlock:(nullable FBSDKAEMReporterBlock)block;

+ (nullable FBSDKAEMInvocation *)_attributedInvocation:(NSArray<FBSDKAEMInvocation *> *)invocations
                                                 Event:(NSString *)event
                                              currency:(nullable NSString *)currency
                                                 value:(nullable NSNumber *)value
                                            parameters:(nullable NSDictionary *)parameters
                                               configs:(NSDictionary<NSString *, NSMutableArray<FBSDKAEMConfiguration *> *> *)configs;

+ (void)_sendAggregationRequest;

+ (NSDictionary<NSString *, id> *)_requestParameters;

+ (NSDictionary<NSString *, id> *)_aggregationRequestParameters:(FBSDKAEMInvocation *)invocation;

+ (BOOL)_isConfigRefreshTimestampValid;

+ (BOOL)_shouldRefresh;

+ (NSMutableDictionary<NSString *, NSMutableArray<FBSDKAEMConfiguration *> *> *)_loadConfigs;

+ (void)_addConfigs:(nullable NSArray<NSDictionary *> *)configs;

+ (NSMutableArray<FBSDKAEMInvocation *> *)_loadReportData;

+ (void)_saveReportData;

+ (void)_clearCache;

@end

@interface FBSDKAEMAdvertiserRuleFactory (Testing)

- (nullable FBSDKAEMAdvertiserMultiEntryRule *)createMultiEntryRuleWithDict:(NSDictionary<NSString *, id> *)dict;

- (nullable FBSDKAEMAdvertiserSingleEntryRule *)createSingleEntryRuleWithDict:(NSDictionary<NSString *, id> *)dict;

- (nullable NSString *)primaryKeyForRule:(NSDictionary<NSString *, id> *)rule;

- (FBSDKAEMAdvertiserRuleOperator)getOperator:(NSDictionary<NSString *, id> *)rule;

- (BOOL)isOperatorForMultiEntryRule:(FBSDKAEMAdvertiserRuleOperator)op;

@end

@interface FBSDKAEMAdvertiserSingleEntryRule (Testing)

- (BOOL)isMatchedWithStringValue:(nullable NSString *)stringValue
                  numericalValue:(nullable NSNumber *)numericalValue;

- (BOOL)isMatchedWithAsteriskParam:(NSString *)param
                   eventParameters:(NSDictionary<NSString *, id> *)eventParams
                         paramPath:(NSArray<NSString *> *)paramPath;

- (BOOL)isRegexMatch:(NSString *)stringValue;

- (BOOL)isAnyOf:(NSArray<NSString *> *)arrayCondition
    stringValue:(NSString *)stringValue
     ignoreCase:(BOOL)ignoreCase;

- (void)setOperator:(FBSDKAEMAdvertiserRuleOperator)op;

@end

NS_ASSUME_NONNULL_END

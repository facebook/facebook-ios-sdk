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

#import "FBSDKAEMConfiguration.h"
#import "FBSDKAEMEvent.h"
#import "FBSDKAEMInvocation.h"
#import "FBSDKAEMReporter.h"
#import "FBSDKAEMRule.h"
#import "FBSDKCoreKit+internal.h"
#import "FBSDKSwizzler+Swizzling.h"
#import "FBSDKSwizzling.h"
#import "FBSDKTestCoder.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKAEMConfiguration (Testing)

+ (nullable NSArray<FBSDKAEMRule *> *)parseRules:(nullable NSArray<NSDictionary<NSString *, id> *> *)rules;

+ (NSSet<NSString *> *)getEventSetFromRules:(NSArray<FBSDKAEMRule *> *)rules;

+ (NSSet<NSString *> *)getCurrencySetFromRules:(NSArray<FBSDKAEMRule *> *)rules;

@end

@interface FBSDKAEMInvocation (Testing)

- (nullable instancetype)initWithCampaignID:(NSString *)campaignID
                                   ACSToken:(NSString *)ACSToken
                            ACSSharedSecret:(nullable NSString *)ACSSharedSecret
                                ACSConfigID:(nullable NSString *)ACSConfigID
                               advertiserID:(nullable NSString *)advertiserID;

- (nullable instancetype)initWithCampaignID:(NSString *)campaignID
                                   ACSToken:(NSString *)ACSToken
                            ACSSharedSecret:(nullable NSString *)ACSSharedSecret
                                ACSConfigID:(nullable NSString *)ACSConfigID
                               advertiserID:(nullable NSString *)advertiserID
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

- (void)_setConfig:(FBSDKAEMConfiguration *)config;

- (void)setRecordedEvents:(NSMutableSet<NSString *> *)recordedEvents;

- (void)setRecordedValues:(NSMutableDictionary<NSString *, NSMutableDictionary *> *)recordedValues;

- (void)setPriority:(NSInteger)priority;

- (void)setConfigID:(NSInteger)configID;

- (void)setConversionTimestamp:(NSDate *_Nonnull)conversionTimestamp;

- (void)reset;

@end

@interface FBSDKAEMReporter (Testing)

+ (void)enable;

+ (void)configureWithRequestProvider:(id<FBSDKGraphRequestProviding>)requestProvider;

+ (nullable FBSDKAEMInvocation *)parseURL:(nullable NSURL *)url;

+ (BOOL)_isConfigRefreshTimestampValid;

+ (NSMutableDictionary<NSString *, NSMutableArray<FBSDKAEMConfiguration *> *> *)_loadConfigs;

+ (void)_addConfigs:(nullable NSArray<NSDictionary *> *)configs;

+ (NSMutableArray<FBSDKAEMInvocation *> *)_loadReportData;

+ (void)_saveReportData;

+ (void)_clearCache;

+ (void)setQueue:(nullable dispatch_queue_t)queue;

+ (void)setTimestamp:(NSDate *)timestamp;

+ (void)setEnabled:(BOOL)enabled;

+ (BOOL)isEnabled;

+ (void)setConfigs:(NSMutableDictionary<NSString *, NSMutableArray<FBSDKAEMConfiguration *> *> *)configs;

+ (NSMutableDictionary<NSString *, NSMutableArray<FBSDKAEMConfiguration *> *> *)getConfigs;

+ (void)setInvocations:(NSMutableArray<FBSDKAEMInvocation *> *)invocations;

+ (NSMutableArray<FBSDKAEMInvocation *> *)getInvocations;

@end

NS_ASSUME_NONNULL_END

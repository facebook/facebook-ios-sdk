/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBAEMInvocation.h"

#import <CommonCrypto/CommonHMAC.h>

#import "FBAEMUtility.h"
#import "FBCoreKitBasicsImportForAEMKit.h"

#define SEC_IN_DAY 86400
#define CATALOG_OPTIMIZATION_MODULUS 8
#define TOP_OUT_PRIORITY 32

static NSString *const CAMPAIGN_ID_KEY = @"campaign_ids";
static NSString *const ACS_TOKEN_KEY = @"acs_token";
static NSString *const ACS_SHARED_SECRET_KEY = @"shared_secret";
static NSString *const ACS_CONFIG_ID_KEY = @"acs_config_id";
static NSString *const BUSINESS_ID_KEY = @"advertiser_id";
static NSString *const CATALOG_ID_KEY = @"catalog_id";
static NSString *const TEST_DEEPLINK_KEY = @"test_deeplink";
static NSString *const TIMESTAMP_KEY = @"timestamp";
static NSString *const CONFIG_MODE_KEY = @"config_mode";
static NSString *const CONFIG_ID_KEY = @"config_id";
static NSString *const RECORDED_EVENTS_KEY = @"recorded_events";
static NSString *const RECORDED_VALUES_KEY = @"recorded_values";
static NSString *const CONVERSION_VALUE_KEY = @"conversion_value";
static NSString *const PRIORITY_KEY = @"priority";
static NSString *const CONVERSION_TIMESTAMP_KEY = @"conversion_timestamp";
static NSString *const IS_AGGREGATED_KEY = @"is_aggregated";
static NSString *const HAS_SKAN_KEY = @"has_skan";
static NSString *const IS_CONVERSION_FILTERING_ELIGIBLE_KEY = @"is_conversion_filtering_eligible";

static NSString *const FB_CONTENT = @"fb_content";
static NSString *const FB_CONTENT_ID = @"fb_content_id";

typedef NSString *const FBAEMInvocationConfigMode;

FBAEMInvocationConfigMode FBAEMInvocationConfigDefaultMode = @"DEFAULT";
FBAEMInvocationConfigMode FBAEMInvocationConfigBrandMode = @"BRAND";
FBAEMInvocationConfigMode FBAEMInvocationConfigCpasMode = @"CPAS";

@implementation FBAEMInvocation

+ (nullable instancetype)invocationWithAppLinkData:(nullable NSDictionary<id, id> *)applinkData
{
  @try {
    applinkData = [FBSDKTypeUtility dictionaryValue:applinkData];
    if (!applinkData) {
      return nil;
    }

    NSString *campaignID = [FBSDKTypeUtility dictionary:applinkData objectForKey:CAMPAIGN_ID_KEY ofType:NSString.class];
    NSString *ACSToken = [FBSDKTypeUtility dictionary:applinkData objectForKey:ACS_TOKEN_KEY ofType:NSString.class];
    NSString *ACSSharedSecret = [FBSDKTypeUtility dictionary:applinkData objectForKey:ACS_SHARED_SECRET_KEY ofType:NSString.class];
    NSString *ACSConfigID = [FBSDKTypeUtility dictionary:applinkData objectForKey:CONFIG_ID_KEY ofType:NSString.class];
    NSString *businessID = [FBSDKTypeUtility dictionary:applinkData objectForKey:BUSINESS_ID_KEY ofType:NSString.class];
    NSString *catalogID = [FBSDKTypeUtility dictionary:applinkData objectForKey:CATALOG_ID_KEY ofType:NSString.class];
    NSNumber *isTestMode = [FBSDKTypeUtility dictionary:applinkData objectForKey:TEST_DEEPLINK_KEY ofType:NSNumber.class] ?: @NO;
    NSNumber *hasSKAN = [FBSDKTypeUtility dictionary:applinkData objectForKey:HAS_SKAN_KEY ofType:NSNumber.class] ?: @NO;
    if (campaignID == nil || ACSToken == nil) {
      return nil;
    }
    return [[FBAEMInvocation alloc] initWithCampaignID:campaignID
                                              ACSToken:ACSToken
                                       ACSSharedSecret:ACSSharedSecret
                                           ACSConfigID:ACSConfigID
                                            businessID:businessID
                                             catalogID:catalogID
                                            isTestMode:isTestMode.boolValue
                                               hasSKAN:hasSKAN.boolValue
                         isConversionFilteringEligible:YES];
  } @catch (NSException *exception) {
    return nil;
  }
}

- (nullable instancetype)initWithCampaignID:(NSString *)campaignID
                                   ACSToken:(NSString *)ACSToken
                            ACSSharedSecret:(nullable NSString *)ACSSharedSecret
                                ACSConfigID:(nullable NSString *)ACSConfigID
                                 businessID:(nullable NSString *)businessID
                                  catalogID:(nullable NSString *)catalogID
                                 isTestMode:(BOOL)isTestMode
                                    hasSKAN:(BOOL)hasSKAN
              isConversionFilteringEligible:(BOOL)isConversionFilteringEligible
{
  return [self initWithCampaignID:campaignID
                               ACSToken:ACSToken
                        ACSSharedSecret:ACSSharedSecret
                            ACSConfigID:ACSConfigID
                             businessID:businessID
                              catalogID:catalogID
                              timestamp:nil
                             configMode:@"DEFAULT"
                               configID:-1
                         recordedEvents:nil
                         recordedValues:nil
                        conversionValue:-1
                               priority:-1
                    conversionTimestamp:nil
                           isAggregated:YES
                             isTestMode:isTestMode
                                hasSKAN:hasSKAN
          isConversionFilteringEligible:isConversionFilteringEligible];
}

- (nullable instancetype)initWithCampaignID:(NSString *)campaignID
                                   ACSToken:(NSString *)ACSToken
                            ACSSharedSecret:(nullable NSString *)ACSSharedSecret
                                ACSConfigID:(nullable NSString *)ACSConfigID
                                 businessID:(nullable NSString *)businessID
                                  catalogID:(nullable NSString *)catalogID
                                  timestamp:(nullable NSDate *)timestamp
                                 configMode:(NSString *)configMode
                                   configID:(NSInteger)configID
                             recordedEvents:(nullable NSMutableSet<NSString *> *)recordedEvents
                             recordedValues:(nullable NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *)recordedValues
                            conversionValue:(NSInteger)conversionValue
                                   priority:(NSInteger)priority
                        conversionTimestamp:(nullable NSDate *)conversionTimestamp
                               isAggregated:(BOOL)isAggregated
                                 isTestMode:(BOOL)isTestMode
                                    hasSKAN:(BOOL)hasSKAN
              isConversionFilteringEligible:(BOOL)isConversionFilteringEligible
{
  if ((self = [super init])) {
    _campaignID = campaignID;
    _ACSToken = ACSToken;
    _ACSSharedSecret = ACSSharedSecret;
    _ACSConfigID = ACSConfigID;
    _businessID = businessID;
    _catalogID = catalogID;
    if ([timestamp isKindOfClass:NSDate.class]) {
      _timestamp = timestamp;
    } else {
      _timestamp = [NSDate date];
    }
    _configMode = configMode;
    _configID = configID;
    if ([recordedEvents isKindOfClass:NSMutableSet.class]) {
      _recordedEvents = recordedEvents;
    } else {
      _recordedEvents = [NSMutableSet new];
    }
    if ([recordedValues isKindOfClass:NSMutableDictionary.class]) {
      _recordedValues = recordedValues;
    } else {
      _recordedValues = [NSMutableDictionary new];
    }
    _conversionValue = conversionValue;
    _priority = priority;
    _conversionTimestamp = conversionTimestamp;
    _isAggregated = isAggregated;
    _isTestMode = isTestMode;
    _hasSKAN = hasSKAN;
    _isConversionFilteringEligible = isConversionFilteringEligible;
  }
  return self;
}

- (BOOL)attributeEvent:(NSString *)event
              currency:(nullable NSString *)currency
                 value:(nullable NSNumber *)value
            parameters:(nullable NSDictionary<NSString *, id> *)parameters
               configs:(nullable NSDictionary<NSString *, NSArray<FBAEMConfiguration *> *> *)configs
     shouldUpdateCache:(BOOL)shouldUpdateCache
{
  FBAEMConfiguration *config = [self _findConfig:configs];
  if ([self _isOutOfWindowWithConfig:config] || ![config.eventSet containsObject:event]) {
    return NO;
  }
  // Check advertiser rule matching
  NSDictionary<NSString *, id> *processedParameters = [self processedParameters:parameters];
  if (config.matchingRule && ![config.matchingRule isMatchedEventParameters:processedParameters]) {
    return NO;
  }
  BOOL isAttributed = NO;
  if (![_recordedEvents containsObject:event]) {
    if (shouldUpdateCache) {
      [_recordedEvents addObject:event];
    }
    isAttributed = YES;
  }
  // Change currency to default currency if currency is not found in currencySet
  NSString *valueCurrency = [currency uppercaseString];
  if (![config.currencySet containsObject:valueCurrency]) {
    valueCurrency = config.defaultCurrency;
  }
  // Use in-segment value for CPAS
  if ([config.configMode isEqualToString:FBAEMInvocationConfigCpasMode]) {
    value = [FBAEMUtility.sharedUtility getInSegmentValue:processedParameters matchingRule:config.matchingRule];
  }
  if (value != nil) {
    NSMutableDictionary<NSString *, id> *mapping = [[FBSDKTypeUtility dictionary:_recordedValues objectForKey:event ofType:NSDictionary.class] mutableCopy] ?: [NSMutableDictionary new];
    NSNumber *valueInMapping = [FBSDKTypeUtility dictionary:mapping objectForKey:valueCurrency ofType:NSNumber.class] ?: @0.0;
    // Overwrite values when the incoming event's value is greater than the cached one
    if (value.doubleValue > valueInMapping.doubleValue) {
      if (shouldUpdateCache) {
        [FBSDKTypeUtility dictionary:mapping setObject:@(value.doubleValue) forKey:valueCurrency];
        [FBSDKTypeUtility dictionary:_recordedValues setObject:mapping forKey:event];
      }
      isAttributed = YES;
    }
  }
  return isAttributed;
}

- (BOOL)updateConversionValueWithConfigs:(nullable NSDictionary<NSString *, NSArray<FBAEMConfiguration *> *> *)configs
                                   event:(NSString *)event
                     shouldBoostPriority:(BOOL)shouldBoostPriority
{
  FBAEMConfiguration *config = [self _findConfig:configs];
  if (!config) {
    return NO;
  }
  BOOL isConversionValueUpdated = NO;
  // Update conversion value if a rule is matched
  for (FBAEMRule *rule in config.conversionValueRules) {
    NSInteger priority = rule.priority;
    if (
      self.isConversionFilteringEligible
      && shouldBoostPriority
      && [rule containsEvent:event]
      && [self isOptimizedEvent:event config:config]
    ) {
      priority += TOP_OUT_PRIORITY;
    }
    if (priority <= _priority) {
      continue;
    }
    if ([rule isMatchedWithRecordedEvents:_recordedEvents recordedValues:_recordedValues]) {
      _conversionValue = rule.conversionValue;
      _priority = priority;
      _conversionTimestamp = [NSDate date];
      _isAggregated = NO;
      isConversionValueUpdated = YES;
    }
  }
  return isConversionValueUpdated;
}

- (BOOL)isOptimizedEvent:(NSString *)event
                 configs:(nullable NSDictionary<NSString *, NSArray<FBAEMConfiguration *> *> *)configs
{
  FBAEMConfiguration *config = [self _findConfig:configs];
  if (!config || !_catalogID) {
    return NO;
  }
  return [self isOptimizedEvent:event config:config];
}

- (BOOL)isOptimizedEvent:(NSString *)event
                  config:(FBAEMConfiguration *)config
{
  // Look up conversion bit mapping to check if an event is optimzied
  for (FBAEMRule *rule in config.conversionValueRules) {
    if ((_campaignID.intValue % CATALOG_OPTIMIZATION_MODULUS)
        == (rule.conversionValue % CATALOG_OPTIMIZATION_MODULUS)) {
      for (FBAEMEvent *entry in rule.events) {
        if ([entry.eventName isEqualToString:event]) {
          return YES;
        }
      }
    }
  }
  return NO;
}

- (BOOL)isOutOfWindowWithConfigs:(nullable NSDictionary<NSString *, NSArray<FBAEMConfiguration *> *> *)configs
{
  FBAEMConfiguration *config = [self _findConfig:configs];
  return [self _isOutOfWindowWithConfig:config];
}

- (nullable NSString *)getHMAC:(NSInteger)delay
{
  if (!_ACSSharedSecret || !_ACSConfigID) {
    return nil;
  }
  @try {
    NSData *secretData = [self decodeBase64UrlSafeString:_ACSSharedSecret];
    if (!secretData) {
      return nil;
    }
    NSMutableData *hmac = [NSMutableData dataWithLength:CC_SHA512_DIGEST_LENGTH];
    NSString *text = [NSString stringWithFormat:@"%@|%@|%@|%@", _campaignID, @(_conversionValue), @(delay), @"server"];
    NSData *clearTextData = [text dataUsingEncoding:NSUTF8StringEncoding];
    CCHmac(kCCHmacAlgSHA512, [secretData bytes], [secretData length], [clearTextData bytes], [clearTextData length], hmac.mutableBytes);
    NSString *base64UrlSafeString = [hmac base64EncodedStringWithOptions:0];
    base64UrlSafeString = [base64UrlSafeString stringByReplacingOccurrencesOfString:@"/"
                                                                         withString:@"_"];
    base64UrlSafeString = [base64UrlSafeString stringByReplacingOccurrencesOfString:@"+"
                                                                         withString:@"-"];
    base64UrlSafeString = [base64UrlSafeString stringByReplacingOccurrencesOfString:@"="
                                                                         withString:@""];
    return base64UrlSafeString;
  } @catch (NSException *exception) {
    return nil;
  }
}

- (nullable NSData *)decodeBase64UrlSafeString:(NSString *)base64UrlSafeString
{
  if (!base64UrlSafeString.length) {
    return nil;
  }
  NSString *base64String = [base64UrlSafeString stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
  base64String = [base64String stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
  base64String = [base64String stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
  NSString *padding = [@"" stringByPaddingToLength:(4 - base64String.length % 4) withString:@"=" startingAtIndex:0];
  base64String = [base64String stringByAppendingString:padding];
  NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
  return decodedData;
}

- (nullable NSDictionary<NSString *, id> *)processedParameters:(nullable NSDictionary<NSString *, id> *)parameters
{
  if (!parameters) {
    return parameters;
  }
  @try {
    NSMutableDictionary<NSString *, id> *result = [NSMutableDictionary dictionaryWithDictionary:parameters];
    NSString *content = [FBSDKTypeUtility dictionary:result objectForKey:FB_CONTENT ofType:NSString.class];
    if (content) {
      [FBSDKTypeUtility dictionary:result
                         setObject:[FBSDKTypeUtility JSONObjectWithData:[content dataUsingEncoding:NSUTF8StringEncoding]
                                                                options:0
                                                                  error:nil]
                            forKey:FB_CONTENT];
    }
    NSString *contentID = [FBSDKTypeUtility dictionary:result objectForKey:FB_CONTENT_ID ofType:NSString.class];
    if (contentID) {
      [FBSDKTypeUtility dictionary:result
                         setObject:[FBSDKTypeUtility JSONObjectWithData:[contentID dataUsingEncoding:NSUTF8StringEncoding]
                                                                options:0
                                                                  error:nil]
                            forKey:FB_CONTENT_ID];
    }
    return [result copy];
  } @catch (NSException *exception) {
    return parameters;
  }
}

- (BOOL)_isOutOfWindowWithConfig:(nullable FBAEMConfiguration *)config
{
  if (!config) {
    return true;
  }
  BOOL isCutoff = [[NSDate date] timeIntervalSinceDate:_timestamp] > config.cutoffTime * SEC_IN_DAY;
  BOOL isOverLastConversionWindow = _conversionTimestamp && [[NSDate date] timeIntervalSinceDate:_conversionTimestamp] > SEC_IN_DAY;
  return isCutoff || isOverLastConversionWindow;
}

- (nullable FBAEMConfiguration *)_findConfig:(nullable NSDictionary<NSString *, NSArray<FBAEMConfiguration *> *> *)configs
{
  NSString *configMode = _businessID ? FBAEMInvocationConfigBrandMode : FBAEMInvocationConfigDefaultMode;
  NSArray<FBAEMConfiguration *> *configList = [self _getConfigList:configMode configs:configs];
  if (0 == configList.count) {
    return nil;
  }
  if (_configID > 0) {
    for (FBAEMConfiguration *config in configList) {
      if ([config isSameValidFrom:_configID businessID:_businessID]) {
        return config;
      }
    }
    return nil;
  } else {
    FBAEMConfiguration *config = nil;
    for (FBAEMConfiguration *c in [configList reverseObjectEnumerator]) {
      if (c.validFrom <= _timestamp.timeIntervalSince1970 && [c isSameBusinessID:_businessID]) {
        config = c;
        break;
      }
    }
    if (!config) {
      return nil;
    }
    [self _setConfig:config];
    return config;
  }
}

- (NSArray<FBAEMConfiguration *> *)_getConfigList:(FBAEMInvocationConfigMode)configMode
                                          configs:(nullable NSDictionary<NSString *, NSArray<FBAEMConfiguration *> *> *)configs
{
  if ([configMode isEqualToString:FBAEMInvocationConfigBrandMode]) {
    NSArray<FBAEMConfiguration *> *brandConfigList = [FBSDKTypeUtility dictionary:configs
                                                                     objectForKey:FBAEMInvocationConfigBrandMode
                                                                           ofType:NSArray.class] ?: @[];
    NSArray<FBAEMConfiguration *> *cpasConfigList = [FBSDKTypeUtility dictionary:configs
                                                                    objectForKey:FBAEMInvocationConfigCpasMode
                                                                          ofType:NSArray.class] ?: @[];
    return [cpasConfigList arrayByAddingObjectsFromArray:brandConfigList];
  }
  return [FBSDKTypeUtility dictionary:configs objectForKey:configMode ofType:NSArray.class] ?: @[];
}

- (void)_setConfig:(FBAEMConfiguration *)config
{
  _configID = config.validFrom;
  _configMode = config.configMode;
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  NSString *campaignID = [decoder decodeObjectOfClass:NSString.class forKey:CAMPAIGN_ID_KEY];
  NSString *ACSToken = [decoder decodeObjectOfClass:NSString.class forKey:ACS_TOKEN_KEY];
  NSString *ACSSharedSecret = [decoder decodeObjectOfClass:NSString.class forKey:ACS_SHARED_SECRET_KEY];
  NSString *ACSConfigID = [decoder decodeObjectOfClass:NSString.class forKey:ACS_CONFIG_ID_KEY];
  NSString *businessID = [decoder decodeObjectOfClass:NSString.class forKey:BUSINESS_ID_KEY];
  NSString *catalogID = [decoder decodeObjectOfClass:NSString.class forKey:CATALOG_ID_KEY];
  NSDate *timestamp = [decoder decodeObjectOfClass:NSDate.class forKey:TIMESTAMP_KEY];
  NSString *configMode = [decoder decodeObjectOfClass:NSString.class forKey:CONFIG_MODE_KEY];
  NSInteger configID = [decoder decodeIntegerForKey:CONFIG_ID_KEY];
  NSMutableSet<NSString *> *recordedEvents = [decoder decodeObjectOfClass:NSMutableSet.class forKey:RECORDED_EVENTS_KEY];
  NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *recordedValues = [decoder decodeObjectOfClass:NSMutableDictionary.class forKey:RECORDED_VALUES_KEY];
  NSInteger conversionValue = [decoder decodeIntegerForKey:CONVERSION_VALUE_KEY];
  NSInteger priority = [decoder decodeIntegerForKey:PRIORITY_KEY];
  NSDate *conversionTimestamp = [decoder decodeObjectOfClass:NSDate.class forKey:CONVERSION_TIMESTAMP_KEY];
  BOOL isAggregated = [decoder decodeBoolForKey:IS_AGGREGATED_KEY];
  BOOL hasSKAN = [decoder decodeBoolForKey:HAS_SKAN_KEY];
  BOOL isConversionFilteringEligible = [decoder decodeBoolForKey:IS_CONVERSION_FILTERING_ELIGIBLE_KEY];
  return [self initWithCampaignID:campaignID
                               ACSToken:ACSToken
                        ACSSharedSecret:ACSSharedSecret
                            ACSConfigID:ACSConfigID
                             businessID:businessID
                              catalogID:catalogID
                              timestamp:timestamp
                             configMode:configMode
                               configID:configID
                         recordedEvents:recordedEvents
                         recordedValues:recordedValues
                        conversionValue:conversionValue
                               priority:priority
                    conversionTimestamp:conversionTimestamp
                           isAggregated:isAggregated
                             isTestMode:NO
                                hasSKAN:hasSKAN
          isConversionFilteringEligible:isConversionFilteringEligible];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:_campaignID forKey:CAMPAIGN_ID_KEY];
  [encoder encodeObject:_ACSToken forKey:ACS_TOKEN_KEY];
  [encoder encodeObject:_ACSSharedSecret forKey:ACS_SHARED_SECRET_KEY];
  [encoder encodeObject:_ACSConfigID forKey:ACS_CONFIG_ID_KEY];
  [encoder encodeObject:_businessID forKey:BUSINESS_ID_KEY];
  [encoder encodeObject:_catalogID forKey:CATALOG_ID_KEY];
  [encoder encodeObject:_timestamp forKey:TIMESTAMP_KEY];
  [encoder encodeObject:_configMode forKey:CONFIG_MODE_KEY];
  [encoder encodeInteger:_configID forKey:CONFIG_ID_KEY];
  [encoder encodeObject:_recordedEvents forKey:RECORDED_EVENTS_KEY];
  [encoder encodeObject:_recordedValues forKey:RECORDED_VALUES_KEY];
  [encoder encodeInteger:_conversionValue forKey:CONVERSION_VALUE_KEY];
  [encoder encodeInteger:_priority forKey:PRIORITY_KEY];
  [encoder encodeObject:_conversionTimestamp forKey:CONVERSION_TIMESTAMP_KEY];
  [encoder encodeBool:_isAggregated forKey:IS_AGGREGATED_KEY];
  [encoder encodeBool:_hasSKAN forKey:HAS_SKAN_KEY];
  [encoder encodeBool:_isConversionFilteringEligible forKey:IS_CONVERSION_FILTERING_ELIGIBLE_KEY];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
  return self;
}

#if DEBUG && FBTEST

- (void)setRecordedEvents:(NSMutableSet<NSString *> *)recordedEvents
{
  _recordedEvents = recordedEvents;
}

- (void)setRecordedValues:(NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *)recordedValues
{
  _recordedValues = recordedValues;
}

- (void)setPriority:(NSInteger)priority
{
  _priority = priority;
}

- (void)setConfigID:(NSInteger)configID
{
  _configID = configID;
}

- (void)setBusinessID:(NSString *_Nullable)businessID
{
  _businessID = businessID;
}

- (void)setCatalogID:(NSString *_Nullable)catalogID
{
  _catalogID = catalogID;
}

- (void)setConversionTimestamp:(NSDate *_Nonnull)conversionTimestamp
{
  _conversionTimestamp = conversionTimestamp;
}

- (void)setConversionValue:(NSInteger)conversionValue
{
  _conversionValue = conversionValue;
}

- (void)setCampaignID:(NSString *_Nonnull)campaignID
{
  _campaignID = campaignID;
}

- (void)setACSSharedSecret:(NSString *_Nullable)ACSSharedSecret
{
  _ACSSharedSecret = ACSSharedSecret;
}

- (void)setACSConfigID:(NSString *_Nullable)ACSConfigID
{
  _ACSConfigID = ACSConfigID;
}

- (void)reset
{
  _timestamp = [NSDate date];
  _configMode = @"DEFAULT";
  _configID = -1;
  _businessID = nil;
  _catalogID = nil;
  _recordedEvents = [NSMutableSet new];
  _recordedValues = [NSMutableDictionary new];
  _conversionValue = -1;
  _priority = -1;
  _conversionTimestamp = [NSDate date];
  _isAggregated = YES;
  _hasSKAN = NO;
  _isConversionFilteringEligible = YES;
}

#endif

@end

#endif

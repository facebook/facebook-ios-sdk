/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKAppEventsConfiguration.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#define FBSDK_APP_EVENTS_CONFIGURATION_DEFAULT_ATE_STATUS_KEY @"default_ate_status"
#define FBSDK_APP_EVENTS_CONFIGURATION_ADVERTISER_ID_TRACKING_ENABLED_KEY @"advertiser_id_collection_enabled"
#define FBSDK_APP_EVENTS_CONFIGURATION_EVENT_COLLECTION_ENABLED_KEY @"event_collection_enabled"
#define FBSDK_APP_EVENTS_CONFIGURATION_IAP_OBSERVATION_TIME_KEY @"ios_iap_observation_time"
#define FBSDK_APP_EVENTS_CONFIGURATION_IAP_MANUAL_AND_AUTO_LOG_DEDUP_WINDOW_MILLIS_KEY @"iap_manual_and_auto_log_dedup_window_millis"
#define FBSDK_APP_EVENTS_CONFIGURATION_IAP_MANUAL_AND_AUTO_LOG_DEDUP_KEYS_KEY @"iap_manual_and_auto_log_dedup_keys"
#define FBSDK_APP_EVENTS_CONFIGURATION_IAP_MANUAL_AND_AUTO_LOG_PROD_DEDUP_KEYS_KEY @"prod_keys"
#define FBSDK_APP_EVENTS_CONFIGURATION_IAP_MANUAL_AND_AUTO_LOG_TEST_DEDUP_KEYS_KEY @"test_keys"

const UInt64 kDefaultIAPObservationTime = 3600000000000;
const UInt64 kDefaultIAPManualAndAutoLogDedupWindow = 60000;

@implementation FBSDKAppEventsConfiguration

- (instancetype)initWithJSON:(nullable NSDictionary<NSString *, id> *)dict
{
  if ((self = [super init])) {
    @try {
      dict = [FBSDKTypeUtility dictionaryValue:dict];
      if (!dict) {
        return FBSDKAppEventsConfiguration.defaultConfiguration;
      }
      NSDictionary<NSString *, id> *configurations = [FBSDKTypeUtility dictionary:dict objectForKey:@"app_events_config" ofType:NSDictionary.class];
      if (!configurations) {
        return FBSDKAppEventsConfiguration.defaultConfiguration;
      }
      NSNumber *defaultATEStatus = [FBSDKTypeUtility numberValue:configurations[FBSDK_APP_EVENTS_CONFIGURATION_DEFAULT_ATE_STATUS_KEY]] ?: @(FBSDKAdvertisingTrackingUnspecified);
      NSNumber *advertiserIDCollectionEnabled = [FBSDKTypeUtility numberValue:configurations[FBSDK_APP_EVENTS_CONFIGURATION_ADVERTISER_ID_TRACKING_ENABLED_KEY]] ?: @(YES);
      NSNumber *eventCollectionEnabled = [FBSDKTypeUtility numberValue:configurations[FBSDK_APP_EVENTS_CONFIGURATION_EVENT_COLLECTION_ENABLED_KEY]] ?: @(NO);
      NSNumber *iapObservationTime = [FBSDKTypeUtility numberValue:configurations[FBSDK_APP_EVENTS_CONFIGURATION_IAP_OBSERVATION_TIME_KEY]] ?: @(kDefaultIAPObservationTime);
      NSNumber *iapManualAndAutoLogDedupWindow = [FBSDKTypeUtility numberValue:configurations[FBSDK_APP_EVENTS_CONFIGURATION_IAP_MANUAL_AND_AUTO_LOG_DEDUP_WINDOW_MILLIS_KEY]] ?: @(kDefaultIAPManualAndAutoLogDedupWindow);
      NSArray *iapManualAndAutologLogDedupKeysResponse = [FBSDKTypeUtility arrayValue:configurations[FBSDK_APP_EVENTS_CONFIGURATION_IAP_MANUAL_AND_AUTO_LOG_DEDUP_KEYS_KEY]];
      if (iapManualAndAutologLogDedupKeysResponse == nil) {
        _iapProdDedupConfiguration = [FBSDKAppEventsConfiguration defaultProdIAPDedupConfiguration];
        _iapTestDedupConfiguration = [FBSDKAppEventsConfiguration defaultTestIAPDedupConfiguration];
      } else {
        [self parseIAPConfigurationFor:iapManualAndAutologLogDedupKeysResponse];
      }
      _defaultATEStatus = defaultATEStatus.integerValue;
      _advertiserIDCollectionEnabled = advertiserIDCollectionEnabled.boolValue;
      _eventCollectionEnabled = eventCollectionEnabled.boolValue;
      _iapObservationTime = iapObservationTime.unsignedLongLongValue;
      _iapManualAndAutoLogDedupWindow = iapManualAndAutoLogDedupWindow.unsignedLongLongValue;
    } @catch (NSException *exception) {
      return FBSDKAppEventsConfiguration.defaultConfiguration;
    }
  }
  return self;
}

- (instancetype)initWithDefaultATEStatus:(FBSDKAdvertisingTrackingStatus)defaultATEStatus
           advertiserIDCollectionEnabled:(BOOL)advertiserIDCollectionEnabled
                  eventCollectionEnabled:(BOOL)eventCollectionEnabled
                      iapObservationTime:(UInt64)iapObservationTime
                 iapManualAndAutoLogDedupWindow:(UInt64)iapManualAndAutoLogDedupWindow
                   iapProdDedupConfiguration:(NSDictionary<NSString *, NSArray<NSString *>*> *)iapProdDedupConfiguration
               iapTestDedupConfiguration:(NSDictionary<NSString *, NSArray<NSString *>*> *)iapTestDedupConfiguration
{
  if ((self = [super init])) {
    _defaultATEStatus = defaultATEStatus;
    _advertiserIDCollectionEnabled = advertiserIDCollectionEnabled;
    _eventCollectionEnabled = eventCollectionEnabled;
    _iapObservationTime = iapObservationTime;
    _iapManualAndAutoLogDedupWindow = iapManualAndAutoLogDedupWindow;
    _iapProdDedupConfiguration = [[NSDictionary alloc] initWithDictionary:iapProdDedupConfiguration];
    _iapTestDedupConfiguration = [[NSDictionary alloc] initWithDictionary:iapTestDedupConfiguration];
  }
  return self;
}

+ (instancetype)defaultConfiguration
{
  FBSDKAppEventsConfiguration* config = [[FBSDKAppEventsConfiguration alloc] initWithDefaultATEStatus:FBSDKAdvertisingTrackingUnspecified
                                         advertiserIDCollectionEnabled:YES
                                                eventCollectionEnabled:NO
                                                    iapObservationTime:kDefaultIAPObservationTime
                                               iapManualAndAutoLogDedupWindow:kDefaultIAPManualAndAutoLogDedupWindow
                                             iapProdDedupConfiguration:[FBSDKAppEventsConfiguration defaultProdIAPDedupConfiguration]
                                             iapTestDedupConfiguration:[FBSDKAppEventsConfiguration defaultTestIAPDedupConfiguration]];
  return config;
}

+ (NSDictionary<NSString *, NSArray<NSString *>*> *) defaultProdIAPDedupConfiguration
{
  return @{
    @"fb_content_id": @[@"fb_content_id"],
    @"fb_content_title": @[@"fb_content_title"],
    @"fb_description": @[@"fb_description"],
    @"fb_transaction_id": @[@"fb_transaction_id"],
    @"_valueToSum": @[@"_valueToSum"],
    @"fb_currency": @[@"fb_currency"]
  };
}

+ (NSDictionary<NSString *, NSArray<NSString *>*> *) defaultTestIAPDedupConfiguration
{
  return @{};
}

- (void) parseIAPConfigurationFor:(NSArray *)responseArray
{
  for (NSDictionary *dict in responseArray) {
    NSString *key = [FBSDKTypeUtility stringValueOrNil:[dict objectForKey:@"key"]];
    NSArray *values = [FBSDKTypeUtility arrayValue:[dict objectForKey:@"value"]];
    if ([key isEqual:FBSDK_APP_EVENTS_CONFIGURATION_IAP_MANUAL_AND_AUTO_LOG_PROD_DEDUP_KEYS_KEY]) {
      _iapProdDedupConfiguration = [self parsedIAPConfigurationFrom:values];
    }
    if ([key isEqual:FBSDK_APP_EVENTS_CONFIGURATION_IAP_MANUAL_AND_AUTO_LOG_TEST_DEDUP_KEYS_KEY]) {
      _iapTestDedupConfiguration = [self parsedIAPConfigurationFrom:values];
    }
  }
  if (_iapProdDedupConfiguration == nil) {
    _iapProdDedupConfiguration = [FBSDKAppEventsConfiguration defaultProdIAPDedupConfiguration];
  }
  if (_iapTestDedupConfiguration == nil) {
    _iapTestDedupConfiguration = [FBSDKAppEventsConfiguration defaultTestIAPDedupConfiguration];
  }
}

- (NSDictionary<NSString *, NSArray<NSString *>*> *) parsedIAPConfigurationFrom:(NSArray *)responseArray
{
  NSMutableDictionary *result = [NSMutableDictionary dictionary];
  if (responseArray == nil) {
    return result;
  }
  for (NSDictionary *dict in responseArray) {
    NSString *key = [FBSDKTypeUtility stringValueOrNil:[dict objectForKey:@"key"]];
    if (key == nil) {
      continue;
    }
    NSArray *values = [FBSDKTypeUtility arrayValue:[dict objectForKey:@"value"]];
    if (values == nil) {
      continue;
    }
    NSMutableArray *resultValues = [NSMutableArray array];
    for (NSDictionary *valueDict in values) {
      NSString *value = [FBSDKTypeUtility stringValueOrNil:[valueDict objectForKey:@"value"]];
      if (value == nil) {
        continue;
      }
      [resultValues addObject:value];
    }
    result[key] = resultValues;
  }
  return result;
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  FBSDKAdvertisingTrackingStatus defaultATEStatus = [decoder decodeIntegerForKey:FBSDK_APP_EVENTS_CONFIGURATION_DEFAULT_ATE_STATUS_KEY];
  BOOL advertisingIDCollectionEnabled = [decoder decodeBoolForKey:FBSDK_APP_EVENTS_CONFIGURATION_ADVERTISER_ID_TRACKING_ENABLED_KEY];
  BOOL eventCollectionEnabled = [decoder decodeBoolForKey:FBSDK_APP_EVENTS_CONFIGURATION_EVENT_COLLECTION_ENABLED_KEY];
  NSNumber *iapObservationTime = [decoder decodeObjectOfClass:NSNumber.class forKey:FBSDK_APP_EVENTS_CONFIGURATION_IAP_OBSERVATION_TIME_KEY];
  NSNumber *iapManualAndAutoLogDedupWindow = [decoder decodeObjectOfClass:NSNumber.class forKey:FBSDK_APP_EVENTS_CONFIGURATION_IAP_MANUAL_AND_AUTO_LOG_DEDUP_WINDOW_MILLIS_KEY];
  NSSet<Class> *classes = [[NSSet alloc] initWithObjects:
                           NSDictionary.class,
                           NSArray.class,
                           NSString.class,
                           nil];
  NSDictionary<NSString *, NSArray<NSString *>*> *iapProdDedupConfig = [decoder decodeObjectOfClasses:classes forKey:FBSDK_APP_EVENTS_CONFIGURATION_IAP_MANUAL_AND_AUTO_LOG_PROD_DEDUP_KEYS_KEY];
  NSDictionary<NSString *, NSArray<NSString *>*> *iapTestDedupConfig = [decoder decodeObjectOfClasses:classes forKey:FBSDK_APP_EVENTS_CONFIGURATION_IAP_MANUAL_AND_AUTO_LOG_TEST_DEDUP_KEYS_KEY];
  return [[FBSDKAppEventsConfiguration alloc] initWithDefaultATEStatus:defaultATEStatus
                                         advertiserIDCollectionEnabled:advertisingIDCollectionEnabled
                                                eventCollectionEnabled:eventCollectionEnabled
                                                    iapObservationTime:iapObservationTime.unsignedLongLongValue
                                               iapManualAndAutoLogDedupWindow:iapManualAndAutoLogDedupWindow.unsignedLongLongValue
                                             iapProdDedupConfiguration:iapProdDedupConfig
                                             iapTestDedupConfiguration:iapTestDedupConfig];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeInteger:_defaultATEStatus forKey:FBSDK_APP_EVENTS_CONFIGURATION_DEFAULT_ATE_STATUS_KEY];
  [encoder encodeBool:_advertiserIDCollectionEnabled forKey:FBSDK_APP_EVENTS_CONFIGURATION_ADVERTISER_ID_TRACKING_ENABLED_KEY];
  [encoder encodeBool:_eventCollectionEnabled forKey:FBSDK_APP_EVENTS_CONFIGURATION_EVENT_COLLECTION_ENABLED_KEY];
  [encoder encodeObject:[NSNumber numberWithUnsignedLongLong:_iapObservationTime] forKey:FBSDK_APP_EVENTS_CONFIGURATION_IAP_OBSERVATION_TIME_KEY];
  [encoder encodeObject:[NSNumber numberWithUnsignedLongLong:_iapManualAndAutoLogDedupWindow] forKey:FBSDK_APP_EVENTS_CONFIGURATION_IAP_MANUAL_AND_AUTO_LOG_DEDUP_WINDOW_MILLIS_KEY];
  [encoder encodeObject:_iapProdDedupConfiguration forKey:FBSDK_APP_EVENTS_CONFIGURATION_IAP_MANUAL_AND_AUTO_LOG_PROD_DEDUP_KEYS_KEY];
  [encoder encodeObject:_iapTestDedupConfiguration forKey:FBSDK_APP_EVENTS_CONFIGURATION_IAP_MANUAL_AND_AUTO_LOG_TEST_DEDUP_KEYS_KEY];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
  return self;
}

#pragma mark - Testability

#if DEBUG

- (void)setDefaultATEStatus:(FBSDKAdvertisingTrackingStatus)status
{
  _defaultATEStatus = status;
}

#endif

@end

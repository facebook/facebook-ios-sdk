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

const UInt64 kDefaultIAPObservationTime = 3600000000000;

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
      _defaultATEStatus = defaultATEStatus.integerValue;
      _advertiserIDCollectionEnabled = advertiserIDCollectionEnabled.boolValue;
      _eventCollectionEnabled = eventCollectionEnabled.boolValue;
      _iapObservationTime = iapObservationTime.unsignedLongLongValue;
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
{
  if ((self = [super init])) {
    _defaultATEStatus = defaultATEStatus;
    _advertiserIDCollectionEnabled = advertiserIDCollectionEnabled;
    _eventCollectionEnabled = eventCollectionEnabled;
    _iapObservationTime = iapObservationTime;
  }
  return self;
}

+ (instancetype)defaultConfiguration
{
  return [[FBSDKAppEventsConfiguration alloc] initWithDefaultATEStatus:FBSDKAdvertisingTrackingUnspecified
                                         advertiserIDCollectionEnabled:YES
                                                eventCollectionEnabled:NO
                                                    iapObservationTime:kDefaultIAPObservationTime];
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
  return [[FBSDKAppEventsConfiguration alloc] initWithDefaultATEStatus:defaultATEStatus
                                         advertiserIDCollectionEnabled:advertisingIDCollectionEnabled
                                                eventCollectionEnabled:eventCollectionEnabled
                                                    iapObservationTime:iapObservationTime.unsignedLongLongValue];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeInteger:_defaultATEStatus forKey:FBSDK_APP_EVENTS_CONFIGURATION_DEFAULT_ATE_STATUS_KEY];
  [encoder encodeBool:_advertiserIDCollectionEnabled forKey:FBSDK_APP_EVENTS_CONFIGURATION_ADVERTISER_ID_TRACKING_ENABLED_KEY];
  [encoder encodeBool:_eventCollectionEnabled forKey:FBSDK_APP_EVENTS_CONFIGURATION_EVENT_COLLECTION_ENABLED_KEY];
  [encoder encodeObject:[NSNumber numberWithUnsignedLongLong:_iapObservationTime] forKey:FBSDK_APP_EVENTS_CONFIGURATION_IAP_OBSERVATION_TIME_KEY];
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

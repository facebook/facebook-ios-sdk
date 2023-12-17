/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <StoreKit/StoreKit.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>
#import <objc/message.h>

#import "FBSDKGraphRequestFactoryProtocol.h"
#import "FBSDKGraphRequestProtocol.h"
#import "FBSDKSKAdNetworkConversionConfiguration.h"

#define FBSDK_SKADNETWORK_CONFIG_TIME_OUT 86400

typedef void (*send_type)(Class, SEL, NSInteger);

typedef void (^FBSDKSKAdNetworkReporterBlock)(void);

static NSString *const FBSDKSKAdNetworkConversionConfigurationKey = @"com.facebook.sdk:FBSDKSKAdNetworkConversionConfiguration";
static NSString *const FBSDKSKAdNetworkReporterKey = @"com.facebook.sdk:FBSDKSKAdNetworkReporter";
static char *const serialQueueLabel = "com.facebook.appevents.SKAdNetwork.FBSDKSKAdNetworkReporter";

@interface FBSDKSKAdNetworkReporterV2 ()

@property (nonatomic) BOOL isSKAdNetworkReportEnabled;
@property (nonnull, nonatomic) NSMutableArray<FBSDKSKAdNetworkReporterBlock> *completionBlocks;
@property (nonatomic) BOOL isRequestStarted;
@property (nonnull, nonatomic) dispatch_queue_t serialQueue;
@property (nullable, nonatomic) FBSDKSKAdNetworkConversionConfiguration *configuration;
@property (nonnull, nonatomic) NSDate *configRefreshTimestamp;
@property (nonatomic) NSInteger conversionValue;
@property (nonatomic) NSInteger lastUpdatedConversionValue;
@property (nonatomic) NSString *coarseConversionValue;
@property (nonatomic) NSDate *timestamp;
@property (nonatomic) NSDate *coarseCVUpdateTimestamp;
@property (nonnull, nonatomic) NSMutableSet<NSString *> *recordedEvents;
@property (nonnull, nonatomic) NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *recordedValues;
@property (nonnull, nonatomic) NSMutableSet<NSString *> *recordedCoarseEvents;
@property (nonnull, nonatomic) NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *recordedCoarseValues;

@end

@implementation FBSDKSKAdNetworkReporterV2

- (instancetype)initWithGraphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                                  dataStore:(id<FBSDKDataPersisting>)dataStore
                     conversionValueUpdater:(Class<FBSDKConversionValueUpdating>)conversionValueUpdater
{
  if ((self = [super init])) {
    _graphRequestFactory = graphRequestFactory;
    _dataStore = dataStore;
    _conversionValueUpdater = conversionValueUpdater;
  }

  return self;
}

- (void)enable
{
  if (@available(iOS 14.0, *)) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      [self _loadReportData];
      self.completionBlocks = [NSMutableArray new];
      self.serialQueue = dispatch_queue_create(serialQueueLabel, DISPATCH_QUEUE_SERIAL);
      [self _loadConfigurationWithBlock:^{
        [self _checkAndUpdateConversionValue];
        [self _checkAndUpdateCoarseConversionValue];
      }];
      self.isSKAdNetworkReportEnabled = YES;
    });
  }
}

- (void)checkAndRevokeTimer
{
  // no-op
}

- (void)recordAndUpdateEvent:(NSString *)event
                    currency:(nullable NSString *)currency
                       value:(nullable NSNumber *)value
                  parameters:(nullable NSDictionary<NSString *, id> *)parameters
{
  [self recordAndUpdateEvent:event currency:currency value:value];
}

- (void)recordAndUpdateEvent:(NSString *)event
                    currency:(nullable NSString *)currency
                       value:(nullable NSNumber *)value
{
  if (@available(iOS 14.0, *)) {
    if (!self.isSKAdNetworkReportEnabled) {
      return;
    }
    if (!event.length) {
      return;
    }
    [self _loadConfigurationWithBlock:^() {
      [self _recordAndUpdateEvent:event currency:currency value:value];
    }];
  }
}

- (void)_loadConfigurationWithBlock:(FBSDKSKAdNetworkReporterBlock)block
{
  if (!self.serialQueue) {
    return;
  }
  // Executes block if there is cache
  if ([self _isConfigRefreshTimestampValid] && [self.dataStore fb_objectForKey:FBSDKSKAdNetworkConversionConfigurationKey]) {
    [self dispatchOnQueue:self.serialQueue block:^() {
      [FBSDKTypeUtility array:self.completionBlocks addObject:block];
      for (FBSDKSKAdNetworkReporterBlock executionBlock in self.completionBlocks) {
        executionBlock();
      }
      [self.completionBlocks removeAllObjects];
    }];
    return;
  }
  [self dispatchOnQueue:self.serialQueue block:^{
    [FBSDKTypeUtility array:self.completionBlocks addObject:block];
    if (self.isRequestStarted) {
      return;
    }
    self.isRequestStarted = YES;
    id<FBSDKGraphRequest> request = [self.graphRequestFactory createGraphRequestWithGraphPath:[NSString stringWithFormat:@"%@/ios_skadnetwork_conversion_config", FBSDKSettings.sharedSettings.appID]
                                                                                   parameters:@{
                                       @"os_version" : UIDevice.currentDevice.systemVersion
                                     }];
    
    [request startWithCompletion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
      [self dispatchOnQueue:self.serialQueue block:^{
        if (error) {
          self.isRequestStarted = NO;
          return;
        }
        NSDictionary<NSString *, id> *json = [FBSDKTypeUtility dictionaryValue:result];
        if (json) {
          [self.dataStore fb_setObject:json forKey:FBSDKSKAdNetworkConversionConfigurationKey];
          self.configRefreshTimestamp = [NSDate date];
          self.configuration = [[FBSDKSKAdNetworkConversionConfiguration alloc] initWithJSON:json];
          for (FBSDKSKAdNetworkReporterBlock executionBlock in self.completionBlocks) {
            executionBlock();
          }
          [self.completionBlocks removeAllObjects];
          self.isRequestStarted = NO;
        }
      }];
    }];
  }];
}

- (void)_recordAndUpdateEvent:(NSString *)event
                     currency:(nullable NSString *)currency
                        value:(nullable NSNumber *)value
{
  if (!self.configuration) {
    return;
  }
  if ([self shouldCutoff] && [self _getCurrentPostbackSequenceIndex] == 1) {
    return;
  }
  BOOL isFineCVCacheUpdated = false;
  if ([self.configuration.eventSet containsObject:event] || [FBSDKAppEventsUtility.shared isStandardEvent:event]) {
    if (![self.recordedEvents containsObject:event]) {
      [self.recordedEvents addObject:event];
      isFineCVCacheUpdated = true;
    }
  }
  BOOL isCoarseCVCacheUpdated = false;
  if ([self.configuration.coarseEventSet containsObject:event] || [FBSDKAppEventsUtility.shared isStandardEvent:event]) {
    if (![self.recordedCoarseEvents containsObject:event]) {
      [self.recordedCoarseEvents addObject:event];
      isCoarseCVCacheUpdated = true;
    }
  }
  // Change currency to default currency if currency is not found in currencySet
  NSString *valueCurrency = currency.uppercaseString;
  if (![self.configuration.currencySet containsObject:valueCurrency]) {
    valueCurrency = self.configuration.defaultCurrency;
  }
  if (value != nil) {
    if ([self.configuration.eventSet containsObject:event] || [FBSDKAppEventsUtility.shared isStandardEvent:event]) {
      NSMutableDictionary<NSString *, id> *fineMapping = [[FBSDKTypeUtility dictionary:self.recordedValues objectForKey:event ofType:NSDictionary.class] mutableCopy] ?: [NSMutableDictionary new];
      NSNumber *fineValueInMapping = [FBSDKTypeUtility dictionary:fineMapping objectForKey:valueCurrency ofType:NSNumber.class] ?: @0.0;
      [FBSDKTypeUtility dictionary:fineMapping setObject:@(fineValueInMapping.doubleValue + value.doubleValue) forKey:valueCurrency];
      [FBSDKTypeUtility dictionary:self.recordedValues setObject:fineMapping forKey:event];
      isFineCVCacheUpdated = true;
    }
    
    if ([self.configuration.coarseEventSet containsObject:event] || [FBSDKAppEventsUtility.shared isStandardEvent:event]) {
      NSMutableDictionary<NSString *, id> *coarseMapping = [[FBSDKTypeUtility dictionary:self.recordedCoarseValues objectForKey:event ofType:NSDictionary.class] mutableCopy] ?: [NSMutableDictionary new];
      NSNumber *coarseValueInMapping = [FBSDKTypeUtility dictionary:coarseMapping objectForKey:valueCurrency ofType:NSNumber.class] ?: @0.0;
      [FBSDKTypeUtility dictionary:coarseMapping setObject:@(coarseValueInMapping.doubleValue + value.doubleValue) forKey:valueCurrency];
      [FBSDKTypeUtility dictionary:self.recordedCoarseValues setObject:coarseMapping forKey:event];
      isCoarseCVCacheUpdated = true;
    }
  }
  if (isFineCVCacheUpdated || isCoarseCVCacheUpdated) {
    [self _checkAndUpdateConversionValue];
    [self _checkAndUpdateCoarseConversionValue];
    [self _saveReportData];
  }
}

- (void)_checkAndUpdateConversionValue
{
  // Update conversion value if a rule is matched
  for (FBSDKSKAdNetworkRule *rule in self.configuration.conversionValueRules) {
    if (rule.conversionValue < self.conversionValue) {
      break;
    }
    if ([rule isMatchedWithRecordedEvents:self.recordedEvents recordedValues:self.recordedValues]) {
      [self _updateConversionValue:rule.conversionValue];
      break;
    }
  }
}

- (void)_checkAndUpdateCoarseConversionValue
{
  // Update coarse conversion value if a rule is matched
  for (FBSDKSKAdNetworkCoarseCVConfig *config in self.configuration.coarseCvConfigs) {
    if (config.postbackSequenceIndex != [self _getCurrentPostbackSequenceIndex]) {
      continue;
    }
    for (FBSDKSKAdNetworkCoarseCVRule *rule in config.cvRules) {
      if (!rule) {
        continue;
      }
      if ([rule isMatchedWithRecordedCoarseEvents:self.recordedCoarseEvents recordedCoarseValues:self.recordedCoarseValues]) {
        [self _updateCoarseConversionValue:rule.coarseCvValue];
        break;
      }
    }
  }
}

- (void)_updateConversionValue:(NSInteger)value
{
  if (@available(iOS 14.0, *)) {
    if ([self shouldCutoff]) {
      return;
    }
    if (@available(iOS 15.4, *)) {
      [self.conversionValueUpdater updatePostbackConversionValue:value completionHandler:nil];
    } else {
      [self.conversionValueUpdater updateConversionValue:value];
    }
    self.conversionValue = value + 1;
    self.lastUpdatedConversionValue = value;
    self.timestamp = [NSDate date];
    [self _saveReportData];
  }
}

- (void)_updateCoarseConversionValue:(NSString *)coarseValue
{
  if (@available(iOS 16.1, *)) {
    if ([self shouldCutoff] && [self _getCurrentPostbackSequenceIndex] == 1) {
      return;
    }
    if ([coarseValue isEqualToString:@"high"]) {
      [self.conversionValueUpdater updatePostbackConversionValue:self.lastUpdatedConversionValue coarseValue:SKAdNetworkCoarseConversionValueHigh completionHandler:nil];
    }
    else if ([coarseValue isEqualToString:@"medium"]) {
      [self.conversionValueUpdater updatePostbackConversionValue:self.lastUpdatedConversionValue coarseValue:SKAdNetworkCoarseConversionValueMedium completionHandler:nil];
    }
    else if ([coarseValue isEqualToString:@"low"]) {
      [self.conversionValueUpdater updatePostbackConversionValue:self.lastUpdatedConversionValue coarseValue:SKAdNetworkCoarseConversionValueLow completionHandler:nil];
    }
    else {
      return;
    }
    self.coarseConversionValue = coarseValue;
    self.coarseCVUpdateTimestamp = [NSDate date];
    [self _saveReportData];
  }
}

- (BOOL)shouldCutoff
{
  if (!self.configuration.cutoffTime) {
    return true;
  }
  NSDate *installTimestamp = [self.dataStore fb_objectForKey:@"com.facebook.sdk:FBSDKSettingsInstallTimestamp"];
  return [installTimestamp isKindOfClass:NSDate.class] && [[NSDate date] timeIntervalSinceDate:installTimestamp] > self.configuration.cutoffTime * 86400;
}

- (BOOL)isReportingEvent:(NSString *)event
{
  return (self.configuration && [self.configuration.eventSet containsObject:event]);
}

- (void)_loadReportData
{
  id cachedJSON = [self.dataStore fb_objectForKey:FBSDKSKAdNetworkConversionConfigurationKey];
  self.configuration = [[FBSDKSKAdNetworkConversionConfiguration alloc] initWithJSON:cachedJSON];
  NSData *cachedReportData = [self.dataStore fb_objectForKey:FBSDKSKAdNetworkReporterKey];
  self.recordedEvents = [NSMutableSet new];
  self.recordedValues = [NSMutableDictionary new];
  self.recordedCoarseEvents = [NSMutableSet new];
  self.recordedCoarseValues = [NSMutableDictionary new];
  if ([cachedReportData isKindOfClass:NSData.class]) {
    NSDictionary<NSString *, id> *data;
    data = [FBSDKTypeUtility dictionaryValue:[NSKeyedUnarchiver
                                              unarchivedObjectOfClasses:[NSSet setWithArray:
                                                                         @[NSString.class,
                                                                           NSNumber.class,
                                                                           NSArray.class,
                                                                           NSDate.class,
                                                                           NSDictionary.class,
                                                                           NSSet.class]]
                                              fromData:cachedReportData
                                              error:nil]];
    if (data) {
      self.conversionValue = [FBSDKTypeUtility integerValue:data[@"conversion_value"]];
      self.lastUpdatedConversionValue = [FBSDKTypeUtility integerValue:data[@"last_updated_conversion_value"]];
      self.coarseConversionValue = [FBSDKTypeUtility stringValueOrNil:data[@"coarse_conversion_value"]] ?: @"none";
      self.timestamp = [FBSDKTypeUtility dictionary:data objectForKey:@"timestamp" ofType:NSDate.class];
      self.coarseCVUpdateTimestamp = [FBSDKTypeUtility dictionary:data objectForKey:@"coarse_cv_update_timestamp" ofType:NSDate.class];
      self.recordedEvents = [[FBSDKTypeUtility dictionary:data objectForKey:@"recorded_events" ofType:NSSet.class] mutableCopy] ?: [NSMutableSet new];
      self.recordedValues = [[FBSDKTypeUtility dictionary:data objectForKey:@"recorded_values" ofType:NSDictionary.class] mutableCopy] ?: [NSMutableDictionary new];
      self.recordedCoarseEvents = [[FBSDKTypeUtility dictionary:data objectForKey:@"recorded_coarse_events" ofType:NSSet.class] mutableCopy] ?: [NSMutableSet new];
      self.recordedCoarseValues = [[FBSDKTypeUtility dictionary:data objectForKey:@"recorded_coarse_values" ofType:NSDictionary.class] mutableCopy] ?: [NSMutableDictionary new];
    }
  }
}

- (void)_saveReportData
{
  NSMutableDictionary<NSString *, id> *reportData = [NSMutableDictionary new];
  [FBSDKTypeUtility dictionary:reportData setObject:@(self.conversionValue) forKey:@"conversion_value"];
  [FBSDKTypeUtility dictionary:reportData setObject:@(self.lastUpdatedConversionValue) forKey:@"last_updated_conversion_value"];
  [FBSDKTypeUtility dictionary:reportData setObject:self.coarseConversionValue forKey:@"coarse_conversion_value"];
  [FBSDKTypeUtility dictionary:reportData setObject:self.timestamp forKey:@"timestamp"];
  [FBSDKTypeUtility dictionary:reportData setObject:self.coarseCVUpdateTimestamp forKey:@"coarse_cv_update_timestamp"];
  [FBSDKTypeUtility dictionary:reportData setObject:self.recordedEvents forKey:@"recorded_events"];
  [FBSDKTypeUtility dictionary:reportData setObject:self.recordedValues forKey:@"recorded_values"];
  [FBSDKTypeUtility dictionary:reportData setObject:self.recordedCoarseEvents forKey:@"recorded_coarse_events"];
  [FBSDKTypeUtility dictionary:reportData setObject:self.recordedCoarseValues forKey:@"recorded_coarse_values"];
  NSData *cache = [NSKeyedArchiver archivedDataWithRootObject:reportData requiringSecureCoding:NO error:nil];
  if (cache) {
    [self.dataStore fb_setObject:cache forKey:FBSDKSKAdNetworkReporterKey];
  }
}

- (void)dispatchOnQueue:(dispatch_queue_t)queue block:(dispatch_block_t)block
{
  if (block != nil) {
    if (strcmp(dispatch_queue_get_label(queue), serialQueueLabel) == 0) {
      dispatch_async(queue, block);
    } else {
      block();
    }
  }
}

- (BOOL)_isConfigRefreshTimestampValid
{
  return self.configRefreshTimestamp && [[NSDate date] timeIntervalSinceDate:self.configRefreshTimestamp] < FBSDK_SKADNETWORK_CONFIG_TIME_OUT;
}

- (NSInteger)_getCurrentPostbackSequenceIndex
{
  NSDate *installTimestamp = [self.dataStore fb_objectForKey:@"com.facebook.sdk:FBSDKSettingsInstallTimestamp"];
  NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:installTimestamp];
  if (interval >= 0 && interval <= 172800) {
    return 1;
  }
  else if (interval > 172800 && interval <= 604800) {
    return 2;
  }
  else if (interval > 604800 && interval <= 3024000) {
    return 3;
  }
  return -1;
}

#pragma mark - Testability

#if DEBUG

- (void)setSKAdNetworkReportEnabled:(BOOL)enabled
{
  self.isSKAdNetworkReportEnabled = enabled;
}

#endif
@end

#endif

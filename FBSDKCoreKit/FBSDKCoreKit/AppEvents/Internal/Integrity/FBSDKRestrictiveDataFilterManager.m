/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKRestrictiveDataFilterManager.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKServerConfigurationManager.h"
#import "FBSDKServerConfigurationProviding.h"

@interface FBSDKRestrictiveEventFilter : NSObject

@property (nonatomic, readonly, copy) NSString *eventName;
@property (nonatomic, readonly, copy) NSDictionary<NSString *, id> *restrictiveParams;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithEventName:(NSString *)eventName
                restrictiveParams:(NSDictionary<NSString *, id> *)restrictiveParams;

@end

@implementation FBSDKRestrictiveEventFilter

- (instancetype)initWithEventName:(NSString *)eventName
                restrictiveParams:(NSDictionary<NSString *, id> *)restrictiveParams
{
  self = [super init];
  if (self) {
    _eventName = [eventName copy];
    _restrictiveParams = [restrictiveParams copy];
  }

  return self;
}

@end

static FBSDKRestrictiveDataFilterManager *_instance;

@interface FBSDKRestrictiveDataFilterManager ()

@property (nonatomic) BOOL isRestrictiveEventFilterEnabled;
@property (nonatomic) NSMutableArray<FBSDKRestrictiveEventFilter *> *params;
@property (nonatomic) NSMutableSet<NSString *> *restrictedEvents;
@property (nonatomic) id<FBSDKServerConfigurationProviding> serverConfigurationProvider;

@end

@implementation FBSDKRestrictiveDataFilterManager

- (instancetype)initWithServerConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider
{
  self.serverConfigurationProvider = serverConfigurationProvider;
  return self;
}

- (void)enable
{
  @synchronized(self) {
    @try {
      if (!self.isRestrictiveEventFilterEnabled) {
        NSDictionary<NSString *, id> *restrictiveParams = [self.serverConfigurationProvider cachedServerConfiguration].restrictiveParams;
        if (restrictiveParams) {
          [self updateFilters:restrictiveParams];
          self.isRestrictiveEventFilterEnabled = YES;
        }
      }
    } @catch (NSException *exception) {}
  }
}

- (nullable NSDictionary<NSString *, id> *)processParameters:(nullable NSDictionary<NSString *, id> *)parameters
                                                   eventName:(NSString *)eventName
{
  if (!self.isRestrictiveEventFilterEnabled) {
    return parameters;
  }
  if (parameters) {
    @try {
      NSMutableDictionary<NSString *, id> *params = [NSMutableDictionary dictionaryWithDictionary:parameters];
      NSMutableDictionary<NSString *, NSString *> *restrictedParams = [NSMutableDictionary dictionary];

      for (NSString *key in [parameters keyEnumerator]) {
        NSString *type = [self getMatchedDataTypeWithEventName:eventName paramKey:key];
        if (type) {
          [FBSDKTypeUtility dictionary:restrictedParams setObject:type forKey:key];
          [params removeObjectForKey:key];
        }
      }

      if ([[restrictedParams allKeys] count] > 0) {
        NSString *restrictedParamsJSONString = [FBSDKBasicUtility JSONStringForObject:restrictedParams
                                                                                error:NULL
                                                                 invalidObjectHandler:NULL];
        [FBSDKTypeUtility dictionary:params setObject:restrictedParamsJSONString forKey:@"_restrictedParams"];
      }

      return [params copy];
    } @catch (NSException *exception) {
      return parameters;
    }
  }

  return nil;
}

- (void)processEvents:(NSArray<NSMutableDictionary<NSString *, id> *> *)events
{
  @try {
    if (!self.isRestrictiveEventFilterEnabled) {
      return;
    }

    static NSString *const REPLACEMENT_STRING = @"_removed_";

    for (NSDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *event in events) {
      if ([self isRestrictedEvent:event[@"event"][@"_eventName"]]) {
        [FBSDKTypeUtility dictionary:event[@"event"] setObject:REPLACEMENT_STRING forKey:@"_eventName"];
      }
    }
  } @catch (NSException *exception) {}
}

#pragma mark - Private Methods

- (BOOL)isRestrictedEvent:(NSString *)eventName
{
  @synchronized(self) {
    return [self.restrictedEvents containsObject:eventName];
  }
}

- (nullable NSString *)getMatchedDataTypeWithEventName:(NSString *)eventName
                                              paramKey:(NSString *)paramKey
{
  // match by params in custom events with event name
  for (FBSDKRestrictiveEventFilter *filter in self.params) {
    if ([filter.eventName isEqualToString:eventName]) {
      NSString *type = [FBSDKTypeUtility coercedToStringValue:filter.restrictiveParams[paramKey]];
      if (type) {
        return type;
      }
    }
  }
  return nil;
}

- (void)updateFilters:(nullable NSDictionary<NSString *, id> *)restrictiveParams
{
  static NSString *const RESTRICTIVE_PARAM_KEY = @"restrictive_param";
  static NSString *const PROCESS_EVENT_NAME_KEY = @"process_event_name";

  restrictiveParams = [FBSDKTypeUtility dictionaryValue:restrictiveParams];
  if (restrictiveParams.count > 0) {
    @synchronized(self) {
      [self.params removeAllObjects];
      [self.restrictedEvents removeAllObjects];
      NSMutableArray<FBSDKRestrictiveEventFilter *> *eventFilterArray = [NSMutableArray array];
      NSMutableSet<NSString *> *restrictedEventSet = [NSMutableSet set];
      for (NSString *eventName in restrictiveParams.allKeys) {
        NSDictionary<NSString *, id> *eventInfo = restrictiveParams[eventName];
        if (!eventInfo) {
          continue;
        }
        if (eventInfo[RESTRICTIVE_PARAM_KEY]) {
          FBSDKRestrictiveEventFilter *restrictiveEventFilter = [[FBSDKRestrictiveEventFilter alloc] initWithEventName:eventName
                                                                                                     restrictiveParams:eventInfo[RESTRICTIVE_PARAM_KEY]];
          [FBSDKTypeUtility array:eventFilterArray addObject:restrictiveEventFilter];
        }
        if (restrictiveParams[eventName][PROCESS_EVENT_NAME_KEY]) {
          [restrictedEventSet addObject:eventName];
        }
      }
      self.params = eventFilterArray;
      self.restrictedEvents = restrictedEventSet;
    }
  }
}

@end

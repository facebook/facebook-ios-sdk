/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKEventDeactivationManager.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKServerConfigurationManager.h"

static NSString *const DEPRECATED_PARAM_KEY = @"deprecated_param";
static NSString *const DEPRECATED_EVENT_KEY = @"is_deprecated_event";

@interface FBSDKDeactivatedEvent : NSObject

@property (nonatomic, readonly, copy) NSString *eventName;
@property (nullable, nonatomic, readonly, copy) NSSet<NSString *> *deactivatedParams;

- (instancetype)initWithEventName:(NSString *)eventName
                deactivatedParams:(NSSet<NSString *> *)deactivatedParams;

@end

@implementation FBSDKDeactivatedEvent

- (instancetype)initWithEventName:(NSString *)eventName
                deactivatedParams:(NSSet<NSString *> *)deactivatedParams
{
  self = [super init];
  if (self) {
    _eventName = eventName;
    _deactivatedParams = deactivatedParams;
  }

  return self;
}

@end

@interface FBSDKEventDeactivationManager ()

@property (nonatomic) BOOL isEventDeactivationEnabled;
@property (nonatomic, strong) NSMutableSet<NSString *> *deactivatedEvents;
@property (nonatomic, strong) NSMutableArray<FBSDKDeactivatedEvent *> *eventsWithDeactivatedParams;
@property (nonatomic) id<FBSDKServerConfigurationProviding> serverConfigurationProvider;

@end

@implementation FBSDKEventDeactivationManager
+ (instancetype)shared
{
  static FBSDKEventDeactivationManager *instance;
  static dispatch_once_t nonce;
  dispatch_once(&nonce, ^{
    instance = [[self alloc] initWithServerConfigurationProvider:FBSDKServerConfigurationManager.shared];
  });
  return instance;
}

- (instancetype)initWithServerConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider
{
  self.isEventDeactivationEnabled = NO;
  self.serverConfigurationProvider = serverConfigurationProvider;
  return self;
}

- (void)enable
{
  @try {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      NSDictionary<NSString *, id> *restrictiveParams = [self.serverConfigurationProvider cachedServerConfiguration].restrictiveParams;
      if (restrictiveParams) {
        [self _updateDeactivatedEvents:restrictiveParams];
        self.isEventDeactivationEnabled = YES;
      }
    });
  } @catch (NSException *exception) {}
}

- (void)processEvents:(NSMutableArray<NSDictionary<NSString *, id> *> *)events
{
  @try {
    if (!self.isEventDeactivationEnabled) {
      return;
    }
    NSArray<NSDictionary<NSString *, id> *> *eventArray = [events copy];
    for (NSDictionary<NSString *, NSDictionary<NSString *, id> *> *event in eventArray) {
      if ([self.deactivatedEvents containsObject:event[@"event"][@"_eventName"]]) {
        [events removeObject:event];
      }
    }
  } @catch (NSException *exception) {}
}

- (nullable NSDictionary<NSString *, id> *)processParameters:(nullable NSDictionary<NSString *, id> *)parameters
                                                   eventName:(NSString *)eventName
{
  @try {
    if (!self.isEventDeactivationEnabled || parameters.count == 0 || self.eventsWithDeactivatedParams.count == 0) {
      return parameters;
    }
    NSMutableDictionary<NSString *, id> *params = [NSMutableDictionary dictionaryWithDictionary:parameters];
    for (NSString *key in [parameters keyEnumerator]) {
      for (FBSDKDeactivatedEvent *event in self.eventsWithDeactivatedParams) {
        if ([event.eventName isEqualToString:eventName] && [event.deactivatedParams containsObject:key]) {
          [params removeObjectForKey:key];
        }
      }
    }
    return [params copy];
  } @catch (NSException *exception) {
    return parameters;
  }
}

#pragma mark - Private Method

- (void)_updateDeactivatedEvents:(nullable NSDictionary<NSString *, id> *)events
{
  events = [FBSDKTypeUtility dictionaryValue:events];
  if (events.count == 0) {
    return;
  }
  [self.deactivatedEvents removeAllObjects];
  [self.eventsWithDeactivatedParams removeAllObjects];
  NSMutableArray<FBSDKDeactivatedEvent *> *deactivatedParamsArray = [NSMutableArray array];
  NSMutableSet<NSString *> *deactivatedEventSet = [NSMutableSet set];
  for (NSString *eventName in events.allKeys) {
    NSDictionary<NSString *, id> *eventInfo = [FBSDKTypeUtility dictionary:events objectForKey:eventName ofType:NSDictionary.class];
    if (!eventInfo) {
      continue;
    }
    if (eventInfo[DEPRECATED_EVENT_KEY]) {
      [deactivatedEventSet addObject:eventName];
    }
    if (eventInfo[DEPRECATED_PARAM_KEY]) {
      FBSDKDeactivatedEvent *eventWithDeactivatedParams = [[FBSDKDeactivatedEvent alloc] initWithEventName:eventName
                                                                                         deactivatedParams:[NSSet setWithArray:eventInfo[DEPRECATED_PARAM_KEY]]];
      [FBSDKTypeUtility array:deactivatedParamsArray addObject:eventWithDeactivatedParams];
    }
  }
  self.deactivatedEvents = deactivatedEventSet;
  self.eventsWithDeactivatedParams = deactivatedParamsArray;
}

@end

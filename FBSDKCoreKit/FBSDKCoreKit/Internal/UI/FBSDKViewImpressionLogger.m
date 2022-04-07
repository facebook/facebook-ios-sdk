/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKViewImpressionLogger.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKAccessToken.h"
#import "FBSDKAccessTokenProtocols.h"
#import "FBSDKAppEvents+Internal.h"
#import "FBSDKEventLogging.h"
#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKNotificationProtocols.h"

@interface FBSDKViewImpressionLogger ()

@property (nonatomic, strong) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (nonatomic, strong) id<FBSDKEventLogging> eventLogger;
@property (nonatomic, strong) id<FBSDKNotificationObserving> notificationObserver;
@property (nonatomic, strong) Class<FBSDKAccessTokenProviding> tokenWallet;
@property (nonatomic) NSMutableSet<NSDictionary<NSString *, id> *> *trackedImpressions;

@end

@implementation FBSDKViewImpressionLogger

static dispatch_once_t token;

#pragma mark - Class Methods

+ (instancetype)impressionLoggerWithEventName:(FBSDKAppEventName)eventName
                          graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                                  eventLogger:(id<FBSDKEventLogging>)eventLogger
                         notificationObserver:(id<FBSDKNotificationObserving>)notificationObserver
                                  tokenWallet:(Class<FBSDKAccessTokenProviding>)tokenWallet
{
  static NSMutableDictionary<NSString *, id> *_impressionTrackers = nil;

  dispatch_once(&token, ^{
    _impressionTrackers = [NSMutableDictionary new];
  });
  // Maintains a single instance of an impression tracker for each event name
  FBSDKViewImpressionLogger *impressionTracker = _impressionTrackers[eventName];
  if (!impressionTracker) {
    impressionTracker = [[self alloc] initWithEventName:eventName
                                    graphRequestFactory:graphRequestFactory
                                            eventLogger:eventLogger
                                   notificationObserver:notificationObserver
                                            tokenWallet:tokenWallet];
    if (!_impressionTrackers) {
      _impressionTrackers = [NSMutableDictionary new];
    }
    [FBSDKTypeUtility dictionary:_impressionTrackers setObject:impressionTracker forKey:eventName];
  }
  return impressionTracker;
}

#pragma mark - Object Lifecycle

- (instancetype)initWithEventName:(FBSDKAppEventName)eventName
              graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                      eventLogger:(id<FBSDKEventLogging>)eventLogger
             notificationObserver:(id<FBSDKNotificationObserving>)notificationObserver
                      tokenWallet:(Class<FBSDKAccessTokenProviding>)tokenWallet
{
  if ((self = [super init])) {
    _eventName = [eventName copy];
    _trackedImpressions = [NSMutableSet new];
    _graphRequestFactory = graphRequestFactory;
    _eventLogger = eventLogger;
    _notificationObserver = notificationObserver;
    _tokenWallet = tokenWallet;

    [self.notificationObserver addObserver:self
                                  selector:@selector(_applicationDidEnterBackgroundNotification:)
                                      name:UIApplicationDidEnterBackgroundNotification
                                    object:UIApplication.sharedApplication];
  }
  return self;
}

#pragma mark - Public API

- (void)logImpressionWithIdentifier:(NSString *)identifier parameters:(nullable NSDictionary<FBSDKAppEventParameterName, id> *)parameters
{
  NSMutableDictionary<NSString *, id> *keys = [NSMutableDictionary dictionary];
  [FBSDKTypeUtility dictionary:keys setObject:identifier forKey:@"__view_impression_identifier__"];
  [keys addEntriesFromDictionary:parameters];
  NSDictionary<NSString *, id> *impressionKey = [keys copy];
  // Ensure that each impression is only tracked once
  if ([_trackedImpressions containsObject:impressionKey]) {
    return;
  }
  [_trackedImpressions addObject:impressionKey];

  [self.eventLogger logInternalEvent:self.eventName
                          parameters:parameters
                  isImplicitlyLogged:YES
                         accessToken:[self.tokenWallet currentAccessToken]];
}

- (void)_applicationDidEnterBackgroundNotification:(NSNotification *)notification
{
  // reset all tracked impressions when the app backgrounds so we will start tracking them again the next time they
  // are triggered.
  [_trackedImpressions removeAllObjects];
}

#if DEBUG

+ (void)reset
{
  if (token) {
    token = 0;
  }
}

- (NSMutableSet<NSDictionary<NSString *, id> *> *)trackedImpressions
{
  return _trackedImpressions;
}

#endif

@end

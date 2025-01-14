/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKGateKeeperManager.h"

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKCoreKit-Swift.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>
#import <objc/runtime.h>

#import "FBSDKGraphRequest.h"
#import "FBSDKGraphRequest+Internal.h"
#import "FBSDKGraphRequestConnecting.h"
#import "FBSDKGraphRequestConnectionFactoryProtocol.h"
#import "FBSDKGraphRequestFactoryProtocol.h"
#import "FBSDKObjectDecoding.h"
#import "FBSDKUnarchiverProvider.h"

#define FBSDK_GATEKEEPERS_USER_DEFAULTS_KEY @"com.facebook.sdk:GateKeepers%@"

#define FBSDK_GATEKEEPER_APP_GATEKEEPER_EDGE @"mobile_sdk_gk"
#define FBSDK_GATEKEEPER_APP_GATEKEEPER_FIELDS @"gatekeepers"

@implementation FBSDKGateKeeperManager

static BOOL _canLoadGateKeepers = NO;
static NSDictionary<NSString *, id> *_gateKeepers;
static NSMutableArray<FBSDKGKManagerBlock> *_completionBlocks;
static const NSTimeInterval kTimeout = 4.0;
static NSDate *_timestamp;
static BOOL _loadingGateKeepers = NO;
static BOOL _requeryFinishedForAppStart = NO;
static id<FBSDKGraphRequestFactory> _graphRequestFactory;
static id<FBSDKGraphRequestConnectionFactory> _graphRequestConnectionFactory;
static id<FBSDKSettings> _settings;
static id<FBSDKDataPersisting> _store;

#pragma mark - Public Class Methods
+ (void)initialize
{
  if (self == FBSDKGateKeeperManager.class) {
    _completionBlocks = [NSMutableArray array];
    _store = nil;
    _graphRequestFactory = nil;
    _graphRequestConnectionFactory = nil;
    _settings = nil;
    _canLoadGateKeepers = NO;
  }
}

+ (void)  configureWithSettings:(id<FBSDKSettings>)settings
            graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
  graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
                          store:(id<FBSDKDataPersisting>)store
{
  _settings = settings;
  _graphRequestFactory = graphRequestFactory;
  _graphRequestConnectionFactory = graphRequestConnectionFactory;
  _store = store;
  _canLoadGateKeepers = YES;
}

+ (BOOL)boolForKey:(NSString *)key defaultValue:(BOOL)defaultValue
{
  [self loadGateKeepers:nil];

  return _gateKeepers[key] != nil ? [_gateKeepers[key] boolValue] : defaultValue;
}

+ (void)loadGateKeepers:(nullable FBSDKGKManagerBlock)completionBlock
{
  @try {
    @synchronized(self) {
      if (!_canLoadGateKeepers) {
        // If we can't load the gatekeepers then it means we didn't have an opportunity
        // to inject our own logger type. Fall back to NSLog for the developer error.
        NSLog(@"Cannot load gate keepers before configuring.");
        return;
      }

      NSString *appID = _settings.appID;
      if (!appID) {
        _gateKeepers = nil;
        if (completionBlock != NULL) {
          completionBlock(nil);
        }
        return;
      }

      if (!_gateKeepers) {
        // load the defaults
        NSString *defaultKey = [NSString stringWithFormat:FBSDK_GATEKEEPERS_USER_DEFAULTS_KEY,
                                appID];
        NSData *data = [self.store fb_objectForKey:defaultKey];
        if ([data isKindOfClass:NSData.class]) {
          id<FBSDKObjectDecoding> unarchiver = [FBSDKUnarchiverProvider createSecureUnarchiverFor:data];
          @try {
            _gateKeepers = [FBSDKTypeUtility dictionaryValue:
                            [unarchiver decodeObjectOfClasses:
                             [NSSet setWithObjects:NSDictionary.class, NSString.class, NSNumber.class, nil]
                                                       forKey:NSKeyedArchiveRootObjectKey]];
          } @catch (NSException *ex) {
            // ignore decoding exceptions
          }
        }
      }

      // Query the server when the requery is not finished for app start or the timestamp is not valid
      if ([self _gateKeeperIsValid]) {
        if (completionBlock) {
          completionBlock(nil);
        }
      } else {
        [FBSDKTypeUtility array:_completionBlocks addObject:completionBlock];
        if (!_loadingGateKeepers) {
          _loadingGateKeepers = YES;
          id<FBSDKGraphRequest> request = [self.class requestToLoadGateKeepers];

          // start request with specified timeout instead of the default 180s
          id<FBSDKGraphRequestConnecting> requestConnection = [self.graphRequestConnectionFactory createGraphRequestConnection];
          requestConnection.timeout = kTimeout;
          [requestConnection addRequest:request completion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
            _requeryFinishedForAppStart = YES;
            [self processLoadRequestResponse:result error:error];
          }];
          [requestConnection start];
        }
      }
    }
  } @catch (NSException *exception) {}
}

#pragma mark - Internal Class Methods

+ (nullable id<FBSDKGraphRequest>)requestToLoadGateKeepers
{
  NSMutableDictionary<NSString *, id> *parameters = [NSMutableDictionary new];
  [FBSDKTypeUtility dictionary:parameters setObject:@"ios" forKey:@"platform"];
  [FBSDKTypeUtility dictionary:parameters setObject:_settings.sdkVersion forKey:@"sdk_version"];
  [FBSDKTypeUtility dictionary:parameters setObject:FBSDK_GATEKEEPER_APP_GATEKEEPER_FIELDS forKey:@"fields"];
  [FBSDKTypeUtility dictionary:parameters setObject:UIDevice.currentDevice.systemVersion forKey:@"os_version"];

  return [self.graphRequestFactory createGraphRequestWithGraphPath:[NSString stringWithFormat:@"%@/%@",
                                                                    _settings.appID, FBSDK_GATEKEEPER_APP_GATEKEEPER_EDGE]
                                                        parameters:parameters
                                                       tokenString:nil
                                                        HTTPMethod:nil
                                                             flags:FBSDKGraphRequestFlagSkipClientToken | FBSDKGraphRequestFlagDisableErrorRecovery
                                 useAlternativeDefaultDomainPrefix:NO];
}

+ (void)processLoadRequestResponse:(id)result error:(NSError *)error
{
  @synchronized(self) {
    _loadingGateKeepers = NO;

    if (!error) {
      // Update the timestamp only when there is no error
      _timestamp = [NSDate date];

      NSMutableDictionary<NSString *, id> *gateKeeper = _gateKeepers.mutableCopy;
      if (!gateKeeper) {
        gateKeeper = [NSMutableDictionary new];
      }
      NSDictionary<NSString *, id> *resultDictionary = [FBSDKTypeUtility dictionaryValue:result];
      NSDictionary<NSString *, id> *fetchedData = [FBSDKTypeUtility dictionaryValue:[resultDictionary[@"data"] firstObject]];
      NSArray<id> *gateKeeperList = fetchedData != nil ? [FBSDKTypeUtility arrayValue:fetchedData[FBSDK_GATEKEEPER_APP_GATEKEEPER_FIELDS]] : nil;

      if (gateKeeperList != nil) {
        // updates gate keeper with fetched data
        for (id gateKeeperEntry in gateKeeperList) {
          NSDictionary<NSString *, id> *entry = [FBSDKTypeUtility dictionaryValue:gateKeeperEntry];
          NSString *key = [FBSDKTypeUtility coercedToStringValue:entry[@"key"]];
          NSNumber *value = [FBSDKTypeUtility numberValue:entry[@"value"]];
          if (entry != nil && key != nil && value != nil) {
            [FBSDKTypeUtility dictionary:gateKeeper setObject:value forKey:key];
          }
        }
        _gateKeepers = [gateKeeper copy];
      }
      // update the cached copy in user defaults
      NSString *defaultKey = [NSString stringWithFormat:FBSDK_GATEKEEPERS_USER_DEFAULTS_KEY,
                              _settings.appID];

      NSData *data = [NSKeyedArchiver archivedDataWithRootObject:gateKeeper requiringSecureCoding:NO error:NULL];

      [self.store fb_setObject:data forKey:defaultKey];
    }

    [self _didProcessGKFromNetwork:error];
  }
}

+ (void)_didProcessGKFromNetwork:(NSError *)error
{
  NSArray<FBSDKGKManagerBlock> *completionBlocks = [NSArray arrayWithArray:_completionBlocks];
  [_completionBlocks removeAllObjects];
  for (FBSDKGKManagerBlock completionBlock in completionBlocks) {
    completionBlock(error);
  }
}

+ (BOOL)_gateKeeperTimestampIsValid:(NSDate *)timestamp
{
  if (timestamp == nil) {
    return NO;
  }
  return ([[NSDate date] timeIntervalSinceDate:timestamp] < FBSDK_GATEKEEPER_MANAGER_CACHE_TIMEOUT);
}

+ (BOOL)_gateKeeperIsValid
{
  if (_requeryFinishedForAppStart && (_timestamp && [self _gateKeeperTimestampIsValid:_timestamp])) {
    return YES;
  }
  return NO;
}

+ (id<FBSDKGraphRequestFactory>)graphRequestFactory
{
  return _graphRequestFactory;
}

+ (id<FBSDKSettings>)settings
{
  return _settings;
}

+ (id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
{
  return _graphRequestConnectionFactory;
}

+ (NSDictionary<NSString *, id> *)gateKeepers
{
  return _gateKeepers;
}

+ (id<FBSDKDataPersisting>)store
{
  return _store;
}

// MARK: - Testability

#if DEBUG

+ (BOOL)canLoadGateKeepers
{
  return _canLoadGateKeepers;
}

+ (void)setGateKeepers:(NSDictionary<NSString *, id> *)gateKeepers
{
  _gateKeepers = gateKeepers;
}

+ (void)setRequeryFinishedForAppStart:(BOOL)isFinished
{
  _requeryFinishedForAppStart = isFinished;
}

+ (void)setTimestamp:(NSDate *)timestamp
{
  _timestamp = timestamp;
}

+ (BOOL)isLoadingGateKeepers
{
  return _loadingGateKeepers;
}

+ (void)setIsLoadingGateKeepers:(BOOL)isLoadingGateKeepers
{
  _loadingGateKeepers = isLoadingGateKeepers;
}

+ (void)reset
{
  _graphRequestFactory = nil;
  _gateKeepers = nil;
  _settings = nil;
  _graphRequestConnectionFactory = nil;
  _store = nil;
  _timestamp = nil;
  _requeryFinishedForAppStart = NO;
  _completionBlocks = [NSMutableArray array];
  _loadingGateKeepers = NO;
  _canLoadGateKeepers = NO;
}

#endif

@end

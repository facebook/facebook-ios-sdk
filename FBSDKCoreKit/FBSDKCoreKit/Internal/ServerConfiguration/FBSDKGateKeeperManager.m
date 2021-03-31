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

#import "FBSDKGateKeeperManager.h"

#import <Foundation/Foundation.h>

#import <objc/runtime.h>

#import "FBSDKAppEventsUtility.h"
#import "FBSDKCoreKit+Internal.h"
#import "FBSDKDataPersisting.h"
#import "FBSDKGraphRequest.h"
#import "FBSDKGraphRequest+Internal.h"
#import "FBSDKGraphRequestConnectionProviding.h"
#import "FBSDKGraphRequestProviding.h"
#import "FBSDKSettings.h"
#import "FBSDKSettingsProtocol.h"

#define FBSDK_GATEKEEPERS_USER_DEFAULTS_KEY @"com.facebook.sdk:GateKeepers%@"

#define FBSDK_GATEKEEPER_APP_GATEKEEPER_EDGE @"mobile_sdk_gk"
#define FBSDK_GATEKEEPER_APP_GATEKEEPER_FIELDS @"gatekeepers"

@implementation FBSDKGateKeeperManager

static BOOL _canLoadGateKeepers;
static NSDictionary<NSString *, id> *_gateKeepers;
static NSMutableArray *_completionBlocks;
static const NSTimeInterval kTimeout = 4.0;
static NSDate *_timestamp;
static BOOL _loadingGateKeepers;
static BOOL _requeryFinishedForAppStart;
static id<FBSDKGraphRequestProviding> _requestProvider;
static id<FBSDKGraphRequestConnectionProviding> _connectionProvider;
static Class<FBSDKSettings> _settings;
static id<FBSDKDataPersisting> _store;
static FBSDKLogger *_logger;

#pragma mark - Public Class Methods
+ (void)initialize
{
  if (self == [FBSDKGateKeeperManager class]) {
    _completionBlocks = [NSMutableArray array];
    _logger = [FBSDKLogger new];
    _store = nil;
    _requestProvider = nil;
    _connectionProvider = nil;
    _settings = nil;
    _canLoadGateKeepers = NO;
  }
}

+ (void)configureWithSettings:(Class<FBSDKSettings>)settings
              requestProvider:(id<FBSDKGraphRequestProviding>)requestProvider
           connectionProvider:(id<FBSDKGraphRequestConnectionProviding>)connectionProvider
                        store:(id<FBSDKDataPersisting>)store
{
  _settings = settings;
  _requestProvider = requestProvider;
  _connectionProvider = connectionProvider;
  _store = store;
  _canLoadGateKeepers = YES;
}

+ (BOOL)boolForKey:(NSString *)key defaultValue:(BOOL)defaultValue
{
  [self loadGateKeepers:nil];

  return _gateKeepers[key] != nil ? [_gateKeepers[key] boolValue] : defaultValue;
}

+ (void)loadGateKeepers:(FBSDKGKManagerBlock)completionBlock
{
  @try {
    @synchronized(self) {
      if (!_canLoadGateKeepers) {
        [self.logger.class singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                                     logEntry:@"Cannot load gate keepers before configuring."];
        return;
      }

      NSString *appID = [self.settings appID];
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
        NSData *data = [self.store objectForKey:defaultKey];
        if ([data isKindOfClass:[NSData class]]) {
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
          id<FBSDKGraphRequest> request = [[self class] requestToLoadGateKeepers];

          // start request with specified timeout instead of the default 180s
          id<FBSDKGraphRequestConnecting> requestConnection = [self.connectionProvider createGraphRequestConnection];
          requestConnection.timeout = kTimeout;
          [requestConnection addRequest:request completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
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
  [FBSDKTypeUtility dictionary:parameters setObject:[self.settings sdkVersion] forKey:@"sdk_version"];
  [FBSDKTypeUtility dictionary:parameters setObject:FBSDK_GATEKEEPER_APP_GATEKEEPER_FIELDS forKey:@"fields"];
  [FBSDKTypeUtility dictionary:parameters setObject:[UIDevice currentDevice].systemVersion forKey:@"os_version"];

  return [self.requestProvider createGraphRequestWithGraphPath:[NSString stringWithFormat:@"%@/%@",
                                                                [self.settings appID], FBSDK_GATEKEEPER_APP_GATEKEEPER_EDGE]
                                                    parameters:parameters
                                                   tokenString:nil
                                                    HTTPMethod:nil
                                                         flags:FBSDKGraphRequestFlagSkipClientToken | FBSDKGraphRequestFlagDisableErrorRecovery];
}

#pragma mark - Helper Class Methods

+ (void)processLoadRequestResponse:(id)result error:(NSError *)error
{
  @synchronized(self) {
    _loadingGateKeepers = NO;

    if (!error) {
      // Update the timestamp only when there is no error
      _timestamp = [NSDate date];

      NSMutableDictionary<NSString *, id> *gateKeeper = [_gateKeepers mutableCopy];
      if (!gateKeeper) {
        gateKeeper = [[NSMutableDictionary alloc] init];
      }
      NSDictionary<NSString *, id> *resultDictionary = [FBSDKTypeUtility dictionaryValue:result];
      NSDictionary<NSString *, id> *fetchedData = [FBSDKTypeUtility dictionaryValue:[resultDictionary[@"data"] firstObject]];
      NSArray<id> *gateKeeperList = fetchedData != nil ? [FBSDKTypeUtility arrayValue:fetchedData[FBSDK_GATEKEEPER_APP_GATEKEEPER_FIELDS]] : nil;

      if (gateKeeperList != nil) {
        // updates gate keeper with fetched data
        for (id gateKeeperEntry in gateKeeperList) {
          NSDictionary<NSString *, id> *entry = [FBSDKTypeUtility dictionaryValue:gateKeeperEntry];
          NSString *key = [FBSDKTypeUtility stringValue:entry[@"key"]];
          NSNumber *value = [FBSDKTypeUtility numberValue:entry[@"value"]];
          if (entry != nil && key != nil && value != nil) {
            [FBSDKTypeUtility dictionary:gateKeeper setObject:value forKey:key];
          }
        }
        _gateKeepers = [gateKeeper copy];
      }
      // update the cached copy in user defaults
      NSString *defaultKey = [NSString stringWithFormat:FBSDK_GATEKEEPERS_USER_DEFAULTS_KEY,
                              [self.settings appID]];

    #if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_11_0
      NSData *data = [NSKeyedArchiver archivedDataWithRootObject:gateKeeper requiringSecureCoding:NO error:NULL];
    #else
      NSData *data = [NSKeyedArchiver archivedDataWithRootObject:gateKeeper];
    #endif

      [self.store setObject:data forKey:defaultKey];
    }

    [self _didProcessGKFromNetwork:error];
  }
}

+ (void)_didProcessGKFromNetwork:(NSError *)error
{
  NSArray *completionBlocks = [NSArray arrayWithArray:_completionBlocks];
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

+ (FBSDKLogger *)logger
{
  return _logger;
}

+ (id<FBSDKGraphRequestProviding>)requestProvider
{
  return _requestProvider;
}

+ (Class<FBSDKSettings>)settings
{
  return _settings;
}

+ (id<FBSDKGraphRequestConnectionProviding>)connectionProvider
{
  return _connectionProvider;
}

+ (NSDictionary *)gateKeepers
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

+ (void)setLogger:(FBSDKLogger *)logger
{
  _logger = logger;
}

+ (void)setGateKeepers:(NSDictionary *)gateKeepers
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
  _requestProvider = nil;
  _gateKeepers = nil;
  _settings = nil;
  _connectionProvider = nil;
  _store = nil;
  _timestamp = nil;
  _requeryFinishedForAppStart = NO;
  _completionBlocks = [NSMutableArray array];
  _loadingGateKeepers = NO;
  _canLoadGateKeepers = NO;
}

#endif

@end

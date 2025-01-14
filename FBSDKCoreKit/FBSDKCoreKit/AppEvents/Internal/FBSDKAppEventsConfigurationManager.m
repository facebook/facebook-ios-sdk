/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKCoreKit-Swift.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>
#import <UIKit/UIKit.h>

static NSString *const FBSDKAppEventsConfigurationKey = @"com.facebook.sdk:FBSDKAppEventsConfiguration";
static NSString *const FBSDKAppEventsConfigurationTimestampKey = @"com.facebook.sdk:FBSDKAppEventsConfigurationTimestamp";
static const NSTimeInterval kTimeout = 4.0;

@interface FBSDKAppEventsConfigurationManager ()

@property (nullable, nonatomic) id<FBSDKDataPersisting> store;
@property (nullable, nonatomic) id<FBSDKSettings> settings;
@property (nullable, nonatomic) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (nullable, nonatomic) id<FBSDKGraphRequestConnectionFactory> graphRequestConnectionFactory;
@property (nonnull, nonatomic) id<FBSDKAppEventsConfiguration> configuration;
@property (nonatomic) BOOL isLoadingConfiguration;
@property (nonatomic) BOOL hasRequeryFinishedForAppStart;
@property (nullable, nonatomic) NSDate *timestamp;
@property (nullable, nonatomic) NSMutableArray<FBSDKAppEventsConfigurationManagerBlock> *completionBlocks;

@end

@implementation FBSDKAppEventsConfigurationManager

// Transitional singleton introduced as a way to change the usage semantics
// from a type-based interface to an instance-based interface.
// The goal of the refactor is to move callsites from:
// ClassWithoutUnderlyingInstance -> ClassRelyingOnUnderlyingInstance -> Instance
static FBSDKAppEventsConfigurationManager *_shared;

+ (FBSDKAppEventsConfigurationManager *)shared
{
  @synchronized(self) {
    if (!_shared) {
      _shared = [self new];
    }
  }

  return _shared;
}

- (void)     configureWithStore:(id<FBSDKDataPersisting>)store
                       settings:(id<FBSDKSettings>)settings
            graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
  graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
{
  self.store = store;
  self.settings = settings;
  self.graphRequestFactory = graphRequestFactory;
  self.graphRequestConnectionFactory = graphRequestConnectionFactory;
  id data = [self.store fb_objectForKey:FBSDKAppEventsConfigurationKey];

  if ([data isKindOfClass:NSData.class]) {
    self.configuration = [NSKeyedUnarchiver unarchivedObjectOfClass:FBSDKAppEventsConfiguration.class fromData:data error:nil];
  }

  if (!self.configuration) {
    self.configuration = FBSDKAppEventsConfiguration.defaultConfiguration;
  }
  self.completionBlocks = [NSMutableArray new];
  self.timestamp = [self.store fb_objectForKey:FBSDKAppEventsConfigurationTimestampKey];
}

- (id<FBSDKAppEventsConfiguration>)cachedAppEventsConfiguration
{
  return self.configuration;
}

- (void)loadAppEventsConfigurationWithBlock:(FBSDKAppEventsConfigurationManagerBlock)block
{
  NSString *appID = self.settings.appID;
  @synchronized(self) {
    [FBSDKTypeUtility array:self.completionBlocks addObject:block];
    if (!appID || (self.hasRequeryFinishedForAppStart && [self _isTimestampValid])) {
      for (FBSDKAppEventsConfigurationManagerBlock completionBlock in self.completionBlocks) {
        completionBlock();
      }
      [self.completionBlocks removeAllObjects];
      return;
    }
    if (self.isLoadingConfiguration) {
      return;
    }
    self.isLoadingConfiguration = true;
    
    id<FBSDKGraphRequest> request = [self.graphRequestFactory createGraphRequestWithGraphPath:appID
                                                                                   parameters:@{
                                       @"fields" : [NSString stringWithFormat:@"app_events_config.os_version(%@)", UIDevice.currentDevice.systemVersion]
                                     }
                                                                                  tokenString:nil
                                                                                   HTTPMethod:FBSDKHTTPMethodGET
                                                                                        flags:FBSDKGraphRequestFlagNone
                                                            useAlternativeDefaultDomainPrefix:NO];
    id<FBSDKGraphRequestConnecting> requestConnection = [self.graphRequestConnectionFactory createGraphRequestConnection];
    requestConnection.timeout = kTimeout;
    [requestConnection addRequest:request completion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
      [self _processResponse:result error:error];
    }];
    [requestConnection start];
  }
}

- (void)_processResponse:(id)response
                   error:(NSError *)error
{
  NSDate *date = [NSDate date];
  @synchronized(self) {
    self.isLoadingConfiguration = NO;
    self.hasRequeryFinishedForAppStart = YES;
    if (error) {
      for (FBSDKAppEventsConfigurationManagerBlock completionBlock in self.completionBlocks) {
        completionBlock();
      }
      [self.completionBlocks removeAllObjects];
      return;
    }
    self.configuration = [[FBSDKAppEventsConfiguration alloc] initWithJSON:response];
    self.timestamp = date;
    for (FBSDKAppEventsConfigurationManagerBlock completionBlock in self.completionBlocks) {
      completionBlock();
    }
    [self.completionBlocks removeAllObjects];
  }
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.configuration requiringSecureCoding:NO error:nil];
  [self.store fb_setObject:data forKey:FBSDKAppEventsConfigurationKey];
  [self.store fb_setObject:date forKey:FBSDKAppEventsConfigurationTimestampKey];
}

- (BOOL)_isTimestampValid
{
  return self.timestamp && [[NSDate date] timeIntervalSinceDate:self.timestamp] < 3600;
}

#if DEBUG

- (void)resetDependencies
{
  self.store = nil;
  self.settings = nil;
  self.graphRequestFactory = nil;
  self.graphRequestConnectionFactory = nil;
}

#endif

@end

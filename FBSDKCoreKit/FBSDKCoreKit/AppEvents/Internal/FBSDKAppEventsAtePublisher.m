/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAppEventsAtePublisher.h"

#import <FBSDKCoreKit/FBSDKGraphRequestFlags.h>
#import <FBSDKCoreKit/FBSDKGraphRequestHTTPMethod.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKAppEventsDeviceInfo.h"
#import "FBSDKDataPersisting.h"
#import "FBSDKGraphRequestConnecting.h"
#import "FBSDKGraphRequestFactoryProtocol.h"
#import "FBSDKGraphRequestProtocol.h"
#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKLogger.h"
#import "FBSDKSettingsProtocol.h"

@interface FBSDKAppEventsAtePublisher ()

@property (nullable, nonatomic) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (nullable, nonatomic) id<FBSDKSettings> settings;
@property (nullable, nonatomic) id<FBSDKDataPersisting> store;
@property (nonatomic) BOOL isProcessing;

@end

@implementation FBSDKAppEventsAtePublisher

- (nullable instancetype)initWithAppIdentifier:(NSString *)appIdentifier
                           graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                                      settings:(id<FBSDKSettings>)settings
                                         store:(id<FBSDKDataPersisting>)store
{
  if ((self = [self init])) {
    NSString *identifier = [FBSDKTypeUtility coercedToStringValue:appIdentifier];
    if (identifier.length == 0) {
      [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors logEntry:@"Missing [FBSDKAppEvents appID] for [FBSDKAppEvents publishATE:]"];
      return nil;
    }
    _appIdentifier = identifier;
    _graphRequestFactory = graphRequestFactory;
    _settings = settings;
    _store = store;
  }
  return self;
}

- (void)publishATE
{
  if (self.isProcessing) {
    return;
  }
  self.isProcessing = YES;
  NSString *lastATEPingString = [NSString stringWithFormat:@"com.facebook.sdk:lastATEPing%@", self.appIdentifier];
  id lastPublishDate = [self.store objectForKey:lastATEPingString];
  if ([lastPublishDate isKindOfClass:NSDate.class] && [(NSDate *)lastPublishDate timeIntervalSinceNow] * -1 < 24 * 60 * 60) {
    self.isProcessing = NO;
    return;
  }

  NSMutableDictionary<NSString *, id> *parameters = [NSMutableDictionary dictionary];
  [FBSDKTypeUtility dictionary:parameters setObject:@"CUSTOM_APP_EVENTS" forKey:@"event"];

  NSOperatingSystemVersion operatingSystemVersion = [FBSDKInternalUtility.sharedUtility operatingSystemVersion];
  NSString *osVersion = [NSString stringWithFormat:@"%ti.%ti.%ti",
                         operatingSystemVersion.majorVersion,
                         operatingSystemVersion.minorVersion,
                         operatingSystemVersion.patchVersion];

  NSArray *event = @[
    @{
      @"_eventName" : @"fb_mobile_ate_status",
      @"ate_status" : @(self.settings.advertisingTrackingStatus).stringValue,
      @"os_version" : osVersion,
    }
  ];
  [FBSDKTypeUtility dictionary:parameters setObject:[FBSDKBasicUtility JSONStringForObject:event error:NULL invalidObjectHandler:NULL] forKey:@"custom_events"];

  [FBSDKAppEventsDeviceInfo extendDictionaryWithDeviceInfo:parameters];

  NSString *path = [NSString stringWithFormat:@"%@/activities", self.appIdentifier];
  id<FBSDKGraphRequest> request = [self.graphRequestFactory createGraphRequestWithGraphPath:path
                                                                                 parameters:parameters
                                                                                tokenString:nil
                                                                                 HTTPMethod:FBSDKHTTPMethodPOST
                                                                                      flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError | FBSDKGraphRequestFlagDisableErrorRecovery];
  __block id<FBSDKDataPersisting> weakStore = self.store;
  [request startWithCompletion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
    if (!error) {
      [weakStore setObject:[NSDate date] forKey:lastATEPingString];
    }
    self.isProcessing = NO;
  }];

#if FBTEST
  self.isProcessing = NO;
#endif
}

@end

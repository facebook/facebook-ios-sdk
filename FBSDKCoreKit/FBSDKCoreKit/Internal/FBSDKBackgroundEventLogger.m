/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKBackgroundEventLogger.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKEventLogging.h"

@interface FBSDKBackgroundEventLogger ()

@property (nonnull, nonatomic, readonly) id<FBSDKInfoDictionaryProviding> infoDictionaryProvider;
@property (nonnull, nonatomic, readonly) id<FBSDKEventLogging> eventLogger;

@end

@implementation FBSDKBackgroundEventLogger

- (instancetype)initWithInfoDictionaryProvider:(id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider
                                   eventLogger:(id<FBSDKEventLogging>)eventLogger
{
  if ((self = [super init])) {
    _infoDictionaryProvider = infoDictionaryProvider;
    _eventLogger = eventLogger;
  }
  return self;
}

- (void)logBackgroundRefreshStatus:(UIBackgroundRefreshStatus)status
{
  BOOL isNewVersion = [self _isNewBackgroundRefresh];
  switch (status) {
    case UIBackgroundRefreshStatusAvailable:
      [_eventLogger logInternalEvent:@"fb_sdk_background_status_available"
                          parameters:@{@"version" : @(isNewVersion ? 1 : 0)}
                  isImplicitlyLogged:YES];
      break;
    case UIBackgroundRefreshStatusDenied:
      [_eventLogger logInternalEvent:@"fb_sdk_background_status_denied"
                  isImplicitlyLogged:YES];
      break;
    case UIBackgroundRefreshStatusRestricted:
      [_eventLogger logInternalEvent:@"fb_sdk_background_status_restricted"
                  isImplicitlyLogged:YES];
      break;
  }
}

- (BOOL)_isNewBackgroundRefresh
{
  if ([_infoDictionaryProvider objectForInfoDictionaryKey:@"BGTaskSchedulerPermittedIdentifiers"]) {
    return YES;
  }
  return NO;
}

@end

#endif

/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAccessTokenExpirer.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKAccessToken.h"
#import "FBSDKApplicationLifecycleNotifications.h"
#import "FBSDKNotificationDelivering.h"
#import "FBSDKNotificationPosting.h"

@interface FBSDKAccessTokenExpirer ()

@property (nonnull, nonatomic, readonly) id<FBSDKNotificationPosting, FBSDKNotificationDelivering> notificationCenter;
@property (nonatomic) NSTimer *timer;

@end

@implementation FBSDKAccessTokenExpirer

- (instancetype)initWithNotificationCenter:(id<FBSDKNotificationPosting, FBSDKNotificationDelivering>)notificationCenter
{
  if ((self = [super init])) {
    _notificationCenter = notificationCenter;
    [notificationCenter fb_addObserver:self
                              selector:@selector(_checkAccessTokenExpirationDate)
                                  name:FBSDKAccessTokenDidChangeNotification
                                object:nil];
    [notificationCenter fb_addObserver:self
                              selector:@selector(_checkAccessTokenExpirationDate)
                                  name:FBSDKApplicationDidBecomeActiveNotification
                                object:nil];
    [self _checkAccessTokenExpirationDate];
  }
  return self;
}

- (void)dealloc
{
  [_timer invalidate];
  _timer = nil;
}

- (void)_checkAccessTokenExpirationDate
{
  [_timer invalidate];
  _timer = nil;
  FBSDKAccessToken *accessToken = FBSDKAccessToken.currentAccessToken;
  if (accessToken == nil || accessToken.isExpired) {
    return;
  }
  _timer = [NSTimer scheduledTimerWithTimeInterval:accessToken.expirationDate.timeIntervalSinceNow target:self selector:@selector(_timerDidFire) userInfo:nil repeats:NO];
}

- (void)_timerDidFire
{
  FBSDKAccessToken *accessToken = FBSDKAccessToken.currentAccessToken;
  NSMutableDictionary<NSString *, id> *userInfo = [NSMutableDictionary dictionary];
  [FBSDKTypeUtility dictionary:userInfo setObject:accessToken forKey:FBSDKAccessTokenChangeNewKey];
  [FBSDKTypeUtility dictionary:userInfo setObject:accessToken forKey:FBSDKAccessTokenChangeOldKey];
  userInfo[FBSDKAccessTokenDidExpireKey] = @YES;

  [self.notificationCenter fb_postNotificationName:FBSDKAccessTokenDidChangeNotification
                                            object:FBSDKAccessToken.class
                                          userInfo:userInfo];
}

@end

/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAppEvents+Internal.h"
#import "FBSDKAppEventsFlushReason.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKSwizzling;
@protocol FBSDKAtePublishing;

@interface FBSDKAppEvents (Testing)

@property (nullable, nonatomic) id<FBSDKAtePublishing> atePublisher;
@property (nonatomic, copy) NSString *pushNotificationsDeviceTokenString;
@property (nullable, nonatomic) Class<FBSDKSwizzling> swizzler;

- (instancetype)initWithFlushBehavior:(FBSDKAppEventsFlushBehavior)flushBehavior
                 flushPeriodInSeconds:(int)flushPeriodInSeconds;
- (void)publishATE;
+ (void)setSingletonInstanceToInstance:(FBSDKAppEvents *)appEvents;
+ (void)setSettings:(id<FBSDKSettings>)settings;
+ (void)reset;

- (void)publishInstall;
- (void)fetchServerConfiguration:(nullable FBSDKCodeBlock)callback;
- (void)instanceLogEvent:(FBSDKAppEventName)eventName
              valueToSum:(NSNumber *)valueToSum
              parameters:(nullable NSDictionary<NSString *, id> *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged
             accessToken:(nullable FBSDKAccessToken *)accessToken;
- (void)applicationDidBecomeActive;
- (void)applicationMovingFromActiveStateOrTerminating;
- (void)setFlushBehavior:(FBSDKAppEventsFlushBehavior)flushBehavior;

+ (FBSDKAppEvents *)shared;

@end

NS_ASSUME_NONNULL_END

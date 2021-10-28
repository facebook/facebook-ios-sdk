/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKAppEvents (Testing)

@property (nullable, nonatomic) id<FBSDKAtePublishing> atePublisher;
- (instancetype)initWithFlushBehavior:(FBSDKAppEventsFlushBehavior)flushBehavior
                 flushPeriodInSeconds:(int)flushPeriodInSeconds;
- (void)publishATE;
+ (void)setSettings:(id<FBSDKSettings>)settings;
+ (void)reset;

@end

NS_ASSUME_NONNULL_END

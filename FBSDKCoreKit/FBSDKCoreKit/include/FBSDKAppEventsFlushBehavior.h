/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

/**
 NS_ENUM (NSUInteger, FBSDKAppEventsFlushBehavior)

 Specifies when `FBSDKAppEvents` sends log events to the server.
 */
typedef NS_ENUM(NSUInteger, FBSDKAppEventsFlushBehavior) {
  /// Flush automatically: periodically (once a minute or every 100 logged events) and always at app reactivation.
  FBSDKAppEventsFlushBehaviorAuto = 0,

  /** Only flush when the `flush` method is called. When an app is moved to background/terminated, the
   events are persisted and re-established at activation, but they will only be written with an
   explicit call to `flush`. */
  FBSDKAppEventsFlushBehaviorExplicitOnly,
} NS_SWIFT_NAME(AppEvents.FlushBehavior);

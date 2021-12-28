/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, FBSDKAppEventsFlushReason) {
  FBSDKAppEventsFlushReasonExplicit,
  FBSDKAppEventsFlushReasonTimer,
  FBSDKAppEventsFlushReasonSessionChange,
  FBSDKAppEventsFlushReasonPersistedEvents,
  FBSDKAppEventsFlushReasonEventThreshold,
  FBSDKAppEventsFlushReasonEagerlyFlushingEvent,
} NS_SWIFT_NAME(AppEventsUtility.FlushReason);

/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import "FBSDKEventLogging.h"
#import "FBSDKSourceApplicationTracking.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(MeasurementEventListener)
@interface FBSDKMeasurementEventListener : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithEventLogger:(id<FBSDKEventLogging>)eventLogger
           sourceApplicationTracker:(id<FBSDKSourceApplicationTracking>)sourceApplicationTracker;

- (void)registerForAppLinkMeasurementEvents;

@end

NS_ASSUME_NONNULL_END

#endif

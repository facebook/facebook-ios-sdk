/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKAccessTokenExpiring.h"

@protocol FBSDKNotificationPosting;
@protocol FBSDKNotificationDelivering;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AccessTokenExpirer)
@interface FBSDKAccessTokenExpirer : NSObject <FBSDKAccessTokenExpiring>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithNotificationCenter:(id<FBSDKNotificationPosting, FBSDKNotificationDelivering>)notificationCenter;

@end

NS_ASSUME_NONNULL_END

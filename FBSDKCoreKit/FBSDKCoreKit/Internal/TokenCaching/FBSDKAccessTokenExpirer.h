/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

@protocol FBSDKNotificationPosting;
@protocol FBSDKNotificationObserving;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AccessTokenExpirer)
@interface FBSDKAccessTokenExpirer : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithNotificationCenter:(id<FBSDKNotificationPosting, FBSDKNotificationObserving>)notificationCenter;

@end

NS_ASSUME_NONNULL_END

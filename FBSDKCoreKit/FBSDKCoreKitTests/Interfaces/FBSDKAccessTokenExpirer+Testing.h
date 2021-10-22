/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAccessTokenExpirer.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKAccessTokenExpirer (Testing)

@property (nonnull, nonatomic, readonly) id<FBSDKNotificationPosting, FBSDKNotificationObserving> notificationCenter;

- (void)_timerDidFire;
- (void)_checkAccessTokenExpirationDate;

@end

NS_ASSUME_NONNULL_END

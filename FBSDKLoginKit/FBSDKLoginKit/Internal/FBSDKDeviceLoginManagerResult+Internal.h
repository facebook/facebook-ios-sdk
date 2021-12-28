/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#if defined BUCK
 #import <FBSDKCoreKit/FBSDKCoreKit.h>
#else
@import FBSDKCoreKit;
#endif

#import "FBSDKDeviceLoginManagerResult.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKDeviceLoginManagerResult ()

/*!
 @abstract Initializes a new instance
 @param token The token
 @param cancelled Indicates if the flow was cancelled.
 */
- (instancetype)initWithToken:(nullable FBSDKAccessToken *)token
                  isCancelled:(BOOL)cancelled NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

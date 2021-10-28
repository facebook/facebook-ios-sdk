/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKAccessToken.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKGraphRequestConnectionFactory;

@interface FBSDKAccessToken (Internal)

@property (class, nullable, nonatomic, copy) id<FBSDKGraphRequestConnectionFactory> graphRequestConnectionFactory;

+ (void)resetTokenCache;

+ (void)setCurrentAccessToken:(nullable FBSDKAccessToken *)token
          shouldDispatchNotif:(BOOL)shouldDispatchNotif;

@end

NS_ASSUME_NONNULL_END

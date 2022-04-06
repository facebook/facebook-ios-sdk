/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKDeviceRequestsHelper.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKDeviceRequestsHelper (Testing)

@property (class, nonatomic, readonly) NSMapTable<id<NSNetServiceDelegate>, id> *mdnsAdvertisementServices;

@end

NS_ASSUME_NONNULL_END

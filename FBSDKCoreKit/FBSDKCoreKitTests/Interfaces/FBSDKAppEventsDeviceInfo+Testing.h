/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAppEventsDeviceInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKAppEventsDeviceInfo (Testing)

@property (nullable, nonatomic, readonly) id<FBSDKSettings> settings;

@end

NS_ASSUME_NONNULL_END

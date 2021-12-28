/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKShareCameraEffectContent.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKInternalUtility;

@interface FBSDKShareCameraEffectContent (Internal)

@property (class, nullable, nonatomic) id<FBSDKInternalUtility> internalUtility;

@end

NS_ASSUME_NONNULL_END

#endif

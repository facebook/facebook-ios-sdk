/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <FBSDKCoreKit/FBSDKProfileProtocols.h>

NS_ASSUME_NONNULL_BEGIN

@class FBSDKProfile;

NS_SWIFT_NAME(ProfileProviding)
@protocol FBSDKProfileProviding

@property (class, nullable, nonatomic, strong) FBSDKProfile *currentProfile
NS_SWIFT_NAME(current);

+ (nullable FBSDKProfile *)fetchCachedProfile;

@end

NS_ASSUME_NONNULL_END

#endif

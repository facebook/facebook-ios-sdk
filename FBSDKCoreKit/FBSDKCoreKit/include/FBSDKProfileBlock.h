/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#if !TARGET_OS_TV

@class FBSDKProfile;

NS_ASSUME_NONNULL_BEGIN

/**
 The callback closure type for loading the current profile.

 @param profile The Profile that was loaded, if any.
 @param error The error that occurred during the request, if any.
 */
typedef void (^ FBSDKProfileBlock)(FBSDKProfile *_Nullable profile, NSError *_Nullable error)
NS_SWIFT_NAME(ProfileBlock);

NS_ASSUME_NONNULL_END

#endif

/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKShareCameraEffectContent+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKShareCameraEffectContent (Testing)

// UNCRUSTIFY_FORMAT_OFF
+ (void)configureWithInternalUtility:(id<FBSDKInternalUtility>)internalUtility
NS_SWIFT_NAME(configure(internalUtility:));
// UNCRUSTIFY_FORMAT_ON

+ (void)resetClassDependencies;

@end

NS_ASSUME_NONNULL_END

#endif

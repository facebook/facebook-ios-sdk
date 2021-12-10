/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKShareCameraEffectContent+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKShareCameraEffectContent (Testing)

+ (void)configureWithInternalUtility:(id<FBSDKInternalUtility>)internalUtility;

+ (void)resetClassDependencies;

@end

NS_ASSUME_NONNULL_END

#endif

/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "TargetConditionals.h"

#if !TARGET_OS_TV

NS_ASSUME_NONNULL_BEGIN
@interface FBSDKLoginRecoveryAttempter : NSObject <FBSDKErrorRecoveryAttempting>

@end

NS_ASSUME_NONNULL_END

#endif

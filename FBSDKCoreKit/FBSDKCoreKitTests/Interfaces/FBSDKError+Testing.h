/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKError+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKErrorReporting;

@interface FBSDKError (Testing)

@property (class, nullable, nonatomic, readonly) id<FBSDKErrorReporting> errorReporter;

+ (void)reset;

@end

NS_ASSUME_NONNULL_END

/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKImpressionLoggingButton (Internal)

@property (class, nullable, nonatomic, readonly) id<FBSDKImpressionLoggerFactory> impressionLoggerFactory;

#if DEBUG
+ (void)resetClassDependencies;
#endif

@end

NS_ASSUME_NONNULL_END

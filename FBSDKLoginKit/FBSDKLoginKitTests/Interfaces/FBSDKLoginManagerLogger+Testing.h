/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKLoginManagerLogger.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKLoginManagerLogger (Testing)

@property (class, nonatomic) id<_FBSDKLoginEventLogging> eventLogger;

+ (void)configureWithEventLogger:(id<_FBSDKLoginEventLogging>)eventLogger;

#if DEBUG
+ (void)resetTypeDependencies;
#endif

@end

NS_ASSUME_NONNULL_END

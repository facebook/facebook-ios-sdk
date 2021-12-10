/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@import FBSDKCoreKit;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKSettings (Testing)

@property (nonatomic) BOOL isConfigured;

- (void)reset;
+ (void)setAutoLogAppEventsEnabled:(BOOL)autoLogAppEventsEnabled;

@end

NS_ASSUME_NONNULL_END

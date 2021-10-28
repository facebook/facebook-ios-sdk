/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKGraphRequestPiggybackManaging.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(GraphRequestPiggybackManagerProviding)
@protocol FBSDKGraphRequestPiggybackManagerProviding

/// Returns a type that conforms to `GraphRequestPiggybackManaging`
+ (Class<FBSDKGraphRequestPiggybackManaging>)piggybackManager;

@end

NS_ASSUME_NONNULL_END

/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKGraphRequestPiggybackManager.h"
#import "FBSDKGraphRequestPiggybackManaging.h"

NS_ASSUME_NONNULL_BEGIN

/// Default conformance to the piggyback managing protocol
@interface FBSDKGraphRequestPiggybackManager (GraphRequestPiggybackManaging) <FBSDKGraphRequestPiggybackManaging>
@end

NS_ASSUME_NONNULL_END

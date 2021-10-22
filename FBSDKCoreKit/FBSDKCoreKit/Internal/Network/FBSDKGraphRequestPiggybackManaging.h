/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@protocol FBSDKGraphRequestConnecting;

#import "FBSDKGraphRequestPiggybackManaging.h"

NS_ASSUME_NONNULL_BEGIN

// Describes a type that can add piggyback requests to connections
NS_SWIFT_NAME(GraphRequestPiggybackManaging)
@protocol FBSDKGraphRequestPiggybackManaging

+ (void)addPiggybackRequests:(id<FBSDKGraphRequestConnecting>)connection;

@end

NS_ASSUME_NONNULL_END

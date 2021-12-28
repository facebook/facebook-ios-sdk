/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKGateKeeperManaging.h"
#import "FBSDKIntegrityManager.h"
#import "FBSDKIntegrityProcessing.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKIntegrityManager (Testing)

@property (nullable, nonatomic) Class<FBSDKGateKeeperManaging> gateKeeperManager;
@property (nullable, nonatomic) id<FBSDKIntegrityProcessing> integrityProcessor;
@property (nonatomic) BOOL isIntegrityEnabled;
@property (nonatomic) BOOL isSampleEnabled;

+ (void)reset;

@end

NS_ASSUME_NONNULL_END

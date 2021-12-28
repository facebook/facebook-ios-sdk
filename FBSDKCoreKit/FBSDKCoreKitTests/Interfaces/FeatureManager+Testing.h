/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKFeatureManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKFeatureManager (Testing)

@property (nullable, nonatomic) Class<FBSDKGateKeeperManaging> gateKeeperManager;
@property (nullable, nonatomic) id<FBSDKSettings> settings;
@property (nullable, nonatomic) id<FBSDKDataPersisting> store;

+ (NSString *)featureName:(FBSDKFeature)feature;
- (void)resetDependencies;

@end

NS_ASSUME_NONNULL_END

/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKFeatureDisabling.h"

@protocol FBSDKGateKeeperManaging;
@protocol FBSDKDataPersisting;
@protocol FBSDKSettings;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(FeatureManager)
@interface FBSDKFeatureManager : NSObject <FBSDKFeatureChecking, FBSDKFeatureDisabling>

@property (class, nonatomic, readonly, strong) FBSDKFeatureManager *shared;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

// UNCRUSTIFY_FORMAT_OFF
- (void)configureWithGateKeeperManager:(Class<FBSDKGateKeeperManaging>)gateKeeperManager
                              settings:(id<FBSDKSettings>)settings
                                 store:(id<FBSDKDataPersisting>)store
NS_SWIFT_NAME(configure(gateKeeperManager:settings:store:));
// UNCRUSTIFY_FORMAT_ON

- (BOOL)isEnabled:(FBSDKFeature)feature;
- (void)checkFeature:(FBSDKFeature)feature
     completionBlock:(FBSDKFeatureManagerBlock)completionBlock;
- (void)disableFeature:(FBSDKFeature)feature;

@end

NS_ASSUME_NONNULL_END

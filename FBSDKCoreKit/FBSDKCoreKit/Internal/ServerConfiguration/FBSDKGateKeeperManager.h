/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKGateKeeperManaging.h"

#define FBSDK_GATEKEEPER_MANAGER_CACHE_TIMEOUT (60 * 60)

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKSettings;
@protocol FBSDKGraphRequestFactory;
@protocol FBSDKGraphRequestConnectionFactory;
@protocol FBSDKDataPersisting;

typedef NSString *const FBSDKGateKeeperKey NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(GateKeeperManager.GateKeeperKey);
typedef void (^ FBSDKGKManagerBlock)(NSError *_Nullable error)
NS_SWIFT_NAME(GKManagerBlock);

NS_SWIFT_NAME(GateKeeperManager)
@interface FBSDKGateKeeperManager : NSObject <FBSDKGateKeeperManaging>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// Configures the manager with various dependencies that are required to load the gate keepers
+ (void)  configureWithSettings:(id<FBSDKSettings>)settings
            graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
  graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
                          store:(id<FBSDKDataPersisting>)store;

/// Returns the locally cached configuration.
+ (BOOL)boolForKey:(NSString *)key defaultValue:(BOOL)defaultValue;

/**
 Load the gate keeper configurations from server

 WARNING: Must call `configure` before loading gate keepers.
 */
+ (void)loadGateKeepers:(nullable FBSDKGKManagerBlock)completionBlock;

@end

NS_ASSUME_NONNULL_END

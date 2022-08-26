/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKGateKeeperManaging.h>

#import <Foundation/Foundation.h>

#define FBSDK_GATEKEEPER_MANAGER_CACHE_TIMEOUT (60 * 60)

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKSettings;
@protocol FBSDKGraphRequestFactory;
@protocol FBSDKGraphRequestConnectionFactory;
@protocol FBSDKDataPersisting;

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
typedef NSString *const FBSDKGateKeeperKey NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(_GateKeeperManager.GateKeeperKey);
typedef void (^ FBSDKGKManagerBlock)(NSError *_Nullable error)
NS_SWIFT_NAME(_GKManagerBlock);

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_GateKeeperManager)
@interface FBSDKGateKeeperManager : NSObject <FBSDKGateKeeperManaging>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (void)  configureWithSettings:(id<FBSDKSettings>)settings
            graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
  graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
                          store:(id<FBSDKDataPersisting>)store
NS_SWIFT_NAME(configure(settings:graphRequestFactory:graphRequestConnectionFactory:store:));

/// Returns the locally cached configuration.
+ (BOOL)boolForKey:(NSString *)key defaultValue:(BOOL)defaultValue;

/**
 Load the gate keeper configurations from server

 WARNING: Must call `configure` before loading gate keepers.
 */
+ (void)loadGateKeepers:(nullable FBSDKGKManagerBlock)completionBlock;

@end

NS_ASSUME_NONNULL_END

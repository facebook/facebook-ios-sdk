/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKServerConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ServerConfigurationBlock)
typedef void (^FBSDKServerConfigurationBlock)(FBSDKServerConfiguration *_Nullable serverConfiguration, NSError *_Nullable error);

NS_SWIFT_NAME(ServerConfigurationProviding)
@protocol FBSDKServerConfigurationProviding

- (FBSDKServerConfiguration *)cachedServerConfiguration;

/**
 Executes the completionBlock with a valid and current configuration when it is available.

 This method will use a cached configuration if it is valid and not expired.
 */
- (void)loadServerConfigurationWithCompletionBlock:(nullable FBSDKServerConfigurationBlock)completionBlock;

- (void)processLoadRequestResponse:(id)result error:(nullable NSError *)error appID:(NSString *)appID;

- (nullable FBSDKGraphRequest *)requestToLoadServerConfiguration:(NSString *)appID;

@end

NS_ASSUME_NONNULL_END

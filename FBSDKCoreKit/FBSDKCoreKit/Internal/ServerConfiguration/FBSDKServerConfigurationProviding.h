/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

@class FBSDKServerConfiguration;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ServerConfigurationBlock)
typedef void (^FBSDKServerConfigurationBlock)(FBSDKServerConfiguration *_Nullable serverConfiguration, NSError *_Nullable error);

NS_SWIFT_NAME(ServerConfigurationProviding)
@protocol FBSDKServerConfigurationProviding

/**
  Executes the completionBlock with a valid and current configuration when it is available.

 This method will use a cached configuration if it is valid and not expired.
 */
- (void)loadServerConfigurationWithCompletionBlock:(nullable FBSDKServerConfigurationBlock)completionBlock;

- (FBSDKServerConfiguration *)cachedServerConfiguration;

@end

NS_ASSUME_NONNULL_END

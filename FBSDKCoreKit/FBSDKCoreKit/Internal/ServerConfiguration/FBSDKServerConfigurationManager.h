/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKServerConfiguration.h"
#import "FBSDKServerConfigurationProviding.h"

#define FBSDK_SERVER_CONFIGURATION_MANAGER_CACHE_TIMEOUT (60 * 60)

@protocol FBSDKGraphRequestFactory;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ServerConfigurationManager)
@interface FBSDKServerConfigurationManager : NSObject

@property (class, readonly) FBSDKServerConfigurationManager *shared;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
  Returns the locally cached configuration.

 The result will be valid for the appID from FBSDKSettings, but may be expired. A network request will be
 initiated to update the configuration if a valid and unexpired configuration is not available.
 */
- (FBSDKServerConfiguration *)cachedServerConfiguration;

/**
  Executes the completionBlock with a valid and current configuration when it is available.

 This method will use a cached configuration if it is valid and not expired.
 */
- (void)loadServerConfigurationWithCompletionBlock:(nullable FBSDKServerConfigurationBlock)completionBlock;

- (void)configureWithGraphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory;

@end

NS_ASSUME_NONNULL_END

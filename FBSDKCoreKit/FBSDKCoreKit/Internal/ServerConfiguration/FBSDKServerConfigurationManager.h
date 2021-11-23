/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKServerConfiguration.h"
#import "FBSDKServerConfigurationProviding.h"

#define FBSDK_SERVER_CONFIGURATION_MANAGER_CACHE_TIMEOUT (60 * 60)

@protocol FBSDKGraphRequestFactory;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ServerConfigurationManager)
@interface FBSDKServerConfigurationManager : NSObject <FBSDKServerConfigurationProviding>

@property (class, readonly) FBSDKServerConfigurationManager *shared;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (nullable, nonatomic) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (nullable, nonatomic) id<FBSDKGraphRequestConnectionFactory> graphRequestConnectionFactory;

// UNCRUSTIFY_FORMAT_OFF
- (void)configureWithGraphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
           graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
  NS_SWIFT_NAME(configure(graphRequestFactory:graphRequestConnectionFactory:));
// UNCRUSTIFY_FORMAT_ON

- (void)clearCache;

@end

NS_ASSUME_NONNULL_END

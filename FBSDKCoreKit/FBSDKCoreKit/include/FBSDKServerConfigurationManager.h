/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKServerConfigurationProviding.h>
#import <Foundation/Foundation.h>

#define FBSDK_SERVER_CONFIGURATION_MANAGER_CACHE_TIMEOUT (60 * 60)

@protocol FBSDKGraphRequestFactory;
@protocol FBSDKGraphRequestConnectionFactory;
@protocol FBSDKDialogConfigurationMapBuilding;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_ServerConfigurationManager)
@interface FBSDKServerConfigurationManager : NSObject <FBSDKServerConfigurationProviding>

@property (class, readonly) FBSDKServerConfigurationManager *shared;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@property (nullable, nonatomic) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (nullable, nonatomic) id<FBSDKGraphRequestConnectionFactory> graphRequestConnectionFactory;
@property (nullable, nonatomic) id<FBSDKDialogConfigurationMapBuilding> dialogConfigurationMapBuilder;

// UNCRUSTIFY_FORMAT_OFF
- (void)configureWithGraphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
           graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
           dialogConfigurationMapBuilder:(id<FBSDKDialogConfigurationMapBuilding>)dialogConfigurationMapBuilder
  NS_SWIFT_NAME(configure(graphRequestFactory:graphRequestConnectionFactory:dialogConfigurationMapBuilder:));
// UNCRUSTIFY_FORMAT_ON

- (void)clearCache;

@end

NS_ASSUME_NONNULL_END

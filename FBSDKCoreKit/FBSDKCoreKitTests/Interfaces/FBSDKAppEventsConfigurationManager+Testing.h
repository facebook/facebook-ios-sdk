/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAppEventsConfigurationManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKAppEventsConfigurationManager (Testing)

@property (class, nonatomic) FBSDKAppEventsConfigurationManager *shared;
@property (nullable, nonatomic) id<FBSDKDataPersisting> store;
@property (nullable, nonatomic) id<FBSDKSettings> settings;
@property (nullable, nonatomic) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (nullable, nonatomic) id<FBSDKGraphRequestConnectionFactory> graphRequestConnectionFactory;
@property (nonatomic) BOOL hasRequeryFinishedForAppStart;
@property (nullable, nonatomic) NSDate *timestamp;
@property (nonnull, nonatomic) id<FBSDKAppEventsConfiguration> configuration;

- (void)_processResponse:(id)response error:(nullable NSError *)error;
- (void)resetDependencies;

@end

NS_ASSUME_NONNULL_END

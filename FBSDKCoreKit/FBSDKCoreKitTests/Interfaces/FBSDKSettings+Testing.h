/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKSettings.h"
#import "FBSDKSettings+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKSettings (Testing)

@property (nullable, nonatomic, readonly) id<FBSDKDataPersisting> store;
@property (nullable, nonatomic) id<FBSDKInfoDictionaryProviding> infoDictionaryProvider;
@property (nullable, nonatomic) id<FBSDKEventLogging> eventLogger;
@property (nullable, nonatomic, readonly) id<FBSDKAppEventsConfigurationProviding> appEventsConfigurationProvider;

- (void)reset;

- (void)setLoggingBehaviors:(NSSet<FBSDKLoggingBehavior> *)loggingBehaviors;

@end

NS_ASSUME_NONNULL_END

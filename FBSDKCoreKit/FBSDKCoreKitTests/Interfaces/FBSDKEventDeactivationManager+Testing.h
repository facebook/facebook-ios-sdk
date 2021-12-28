/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKEventDeactivationManager.h"

@protocol FBSDKServerConfigurationProviding;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKEventDeactivationManager (Testing)

- (instancetype)initWithServerConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider;

@end

NS_ASSUME_NONNULL_END

/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKShareDialogConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKServerConfigurationProviding;

@interface FBSDKShareDialogConfiguration (Testing)

@property (nonatomic) id<FBSDKServerConfigurationProviding> serverConfigurationProvider;

- (instancetype)initWithServerConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider;

@end

NS_ASSUME_NONNULL_END

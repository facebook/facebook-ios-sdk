/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKDomainHandler.h"
#import "FBSDKDomainConfigurationManager.h"
#import <FBSDKCoreKit/FBSDKDomainConfigurationProviding.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKDomainHandler (Testing)

@property (nullable, nonatomic) id<FBSDKDomainConfigurationProviding> domainConfigurationProvider;

@end

NS_ASSUME_NONNULL_END


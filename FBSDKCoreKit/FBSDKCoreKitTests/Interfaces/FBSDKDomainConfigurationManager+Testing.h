/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKDomainConfigurationManager.h"
#import "FBSDKDomainConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKDomainConfigurationManager (Testing)

@property (nullable, nonatomic) FBSDKDomainConfiguration *domainConfiguration;
@property (nullable, nonatomic) NSError *domainConfigurationError;

- (instancetype)initWithDomainConfiguration:(nullable FBSDKDomainConfiguration *)domainConfiguration;
- (void)reset;
- (void)processLoadRequestResponse:(id)result error:(nullable NSError *)error;

@end

NS_ASSUME_NONNULL_END

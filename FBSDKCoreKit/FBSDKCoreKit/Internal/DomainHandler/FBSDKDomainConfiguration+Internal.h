/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKDomainConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT const NSInteger FBSDKDomainConfigurationVersion;
FOUNDATION_EXPORT NSString *const kEndpoint1URLPrefix;
FOUNDATION_EXPORT NSString *const kEndpoint2URLPrefix;

@interface FBSDKDomainConfiguration (Internal)

+ (FBSDKDomainConfiguration *)defaultDomainConfiguration;
+ (void)resetDefaultDomainInfo;

@end

NS_ASSUME_NONNULL_END

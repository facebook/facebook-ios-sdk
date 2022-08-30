/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKCoreKit.h>

@implementation FBSDKErrorConfigurationProvider

- (id<FBSDKErrorConfiguration>)errorConfiguration
{
  return FBSDKServerConfigurationManager.shared.cachedServerConfiguration.errorConfiguration
  ?: [[FBSDKErrorConfiguration alloc] initWithDictionary:nil];
}

@end

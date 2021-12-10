/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKErrorConfigurationProvider.h"

#import "FBSDKServerConfigurationManager.h"

@implementation FBSDKErrorConfigurationProvider

- (id<FBSDKErrorConfiguration>)errorConfiguration
{
  return FBSDKServerConfigurationManager.shared.cachedServerConfiguration.errorConfiguration
  ?: [[FBSDKErrorConfiguration alloc] initWithDictionary:nil];
}

@end
